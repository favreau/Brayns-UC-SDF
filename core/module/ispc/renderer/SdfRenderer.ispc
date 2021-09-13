/* Copyright (c) 2018, Cyrille Favreau
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
 *
 * This code a translation from:
 * https://www.shadertoy.com/view/4sX3Rn
 *
 * The MIT License
 * Copyright © 2013 Inigo Quilez
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions: The above copyright
 * notice and this permission notice shall be included in all copies or
 * substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS",
 * WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 * FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "Glsl.ih"
#include "Sdf.ih"
#include "SdfRenderer.ih"

const float FAR_PLANE = 100.f;

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

inline vec4f map(const uniform SdfRenderer* uniform self, vec3f& p)
{
    vec3f point = p - make_vec3f(0.5f);
    const vec3f radius = make_vec3f(1.f);
    float d = sdBox(point, radius);
    vec4f res = make_vec4f(d);

    float s = 1.f;
    float ani = 0.f;
    float off = 0.f;
    for (int m = 0; m < self->nbIterations; m++)
    {
        if (m == 0)
        {
            ani = smoothstep(-0.2f, 0.2f, -cos(0.5f * self->timer));
            off = 1.5f * sin(0.01f * self->timer);
        }

        const vec3f ma = self->ma * (point + off);
        point = make_vec3f(mix(point.x, ma.x, ani), mix(point.y, ma.y, ani),
                           mix(point.z, ma.z, ani));

        const vec3f a = mod(point * s, 2.f) - 1.f;
        s *= 3.f;
        const vec3f r = abs(1.f - 3.f * abs(a));
        const float da = max(r.x, r.y);
        const float db = max(r.y, r.z);
        const float dc = max(r.z, r.x);
        const float c = (min(da, min(db, dc)) - 1.f) / s;

        if (c > d)
        {
            d = c;
            res = make_vec4f(d, min(res.y, 0.2f * da * db * dc),
                             (1.f + (float)m) / 4.f, 0.f);
        }
    }

    return res;
}

inline vec4f intersect(const uniform SdfRenderer* uniform self, const vec3f& ro,
                       const vec3f& rd)
{
    float t = 0.f;
    vec4f res = make_vec4f(-1.f);
    vec4f h = make_vec4f(1.f);
    for (int i = 0; i < self->samplesPerRay; ++i)
    {
        if (h.x < 0.0001f || t > FAR_PLANE)
            break;
        h = map(self, ro + rd * t);
        res = make_vec4f(t, h.y, h.z, h.w);
        t += h.x;
    }
    if (t > FAR_PLANE)
        res = make_vec4f(-1.f);
    return res;
}

inline float softshadow(const uniform SdfRenderer* uniform self,
                        const vec3f& ro, const vec3f& rd, float mint, float k)
{
    float res = 1.f;
    float t = mint;
    float h = 1.f;
    for (int i = 0; i < 32; i++)
    {
        const vec4f a = map(self, ro + rd * t);
        h = a.x;
        res = min(res, k * h / t);
        t += clamp(h, self->softShadows, 0.1f);
    }
    return clamp(res, 0.f, 1.f);
}

inline vec3f calcNormal(const uniform SdfRenderer* uniform self,
                        const vec3f& pos)
{
    vec3f eps = make_vec3f(0.001f, 0.f, 0.f);

    const vec4f x0 = map(self, pos + make_vec3f(eps.x, eps.y, eps.y));
    const vec4f x1 = map(self, pos - make_vec3f(eps.x, eps.y, eps.y));
    const vec4f y0 = map(self, pos + make_vec3f(eps.y, eps.x, eps.y));
    const vec4f y1 = map(self, pos - make_vec3f(eps.y, eps.x, eps.y));
    const vec4f z0 = map(self, pos + make_vec3f(eps.y, eps.y, eps.x));
    const vec4f z1 = map(self, pos - make_vec3f(eps.y, eps.y, eps.x));

    return normalize(make_vec3f(x0.x - x1.x, y0.x - y1.x, z0.x - z1.x));
}

inline vec3f render(const uniform SdfRenderer* uniform self, const vec3f& ro,
                    const vec3f& rd)
{
    // background color
    vec3f col =
        make_vec3f(mix(self->bgColor.x * 0.5f, 0.7f, 0.5f + 0.5f * rd.y),
                   mix(self->bgColor.y * 0.5f, 0.9f, 0.5f + 0.5f * rd.y),
                   mix(self->bgColor.z * 0.5f, 1.0f, 0.5f + 0.5f * rd.y));

    vec4f tmat = intersect(self, ro, rd);
    if (tmat.x > 0.f)
    {
        // Shading
        const uniform Light* uniform light = self->lights[0];
        const vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        const Light_SampleRes lightSample = light->sample(light, dg, s);
        const vec3f radiance = lightSample.weight;
        const vec3f lightDirection = lightSample.dir;

        const vec3f pos = ro + tmat.x * rd;
        const vec3f normal = calcNormal(self, pos);

        const float occ = tmat.y;
        const float sha =
            self->shadows > 0.f
                ? softshadow(self, pos, lightDirection, 0.01f, 64.f)
                : 1.f;

        const float dif = max(0.1f + 0.9f * dot(normal, lightDirection), 0.f);
        const float sky = 0.5f + 0.5f * normal.y;
        const float bac =
            max(0.4f + 0.6f * dot(normal, neg(lightDirection)), 0.f);

        vec3f lin = make_vec3f(0.f);
        lin = lin + 1.f * dif * make_vec3f(1.1f, 0.85f, 0.6f) * sha;
        lin = lin + 0.5f * sky * make_vec3f(0.1f, 0.2f, 0.4f) * occ;
        lin = lin + 0.1f * bac * make_vec3f(1.f) * (0.5f + 0.5f * occ);
        lin = lin + 0.25f * occ * make_vec3f(0.15f, 0.17f, 0.2f);

        const vec3f matcol = make_vec3f(0.5f + 0.5f * cos(0.f + 2.f * tmat.z),
                                        0.5f + 0.5f * cos(1.f + 2.f * tmat.z),
                                        0.5f + 0.5f * cos(2.f + 2.f * tmat.z));
        col = matcol * lin;
    }

    const float e = 0.4545f;
    return make_vec3f(pow(col.x, e), pow(col.y, e), pow(col.z, e));
}

inline vec3f SdfRenderer_shadeRay(const uniform SdfRenderer* uniform self,
                                  varying ScreenSample& sample)
{
    sample.alpha = 1.f;
    sample.z = inf;

    return render(self, sample.ray.org, sample.ray.dir);
}

void SdfRenderer_renderSample(uniform Renderer* uniform _self,
                              void* uniform perFrameData,
                              varying ScreenSample& sample)
{
    uniform SdfRenderer* uniform self = (uniform SdfRenderer * uniform) _self;
    sample.rgb = SdfRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform SdfRenderer_create(void* uniform cppE)
{
    uniform SdfRenderer* uniform self = uniform new uniform SdfRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = SdfRenderer_renderSample;
    return self;
}

export void SdfRenderer_set(void* uniform _self, const uniform vec3f& bgColor,
                            const uniform float& shadows,
                            const uniform float& softShadows,
                            const uniform int& spp, void** uniform lights,
                            const uniform int32 numLights,
                            const uniform int32& samplesPerRay,
                            const uniform float& timestamp,
                            const uniform int32& nbIterations)
{
    uniform SdfRenderer* uniform self = (uniform SdfRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->spp = spp;
    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;
    self->samplesPerRay = samplesPerRay;
    self->nbIterations = nbIterations;
    self->timer = timestamp;

    self->ma = make_LinearSpace3f(make_vec3f(0.6f, 0.f, 0.8f),
                                  make_vec3f(0.f, 1.f, 0.f),
                                  make_vec3f(-0.8f, 0.f, 0.6f));
}
