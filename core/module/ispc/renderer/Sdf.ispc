/* Copyright (c) 2021, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-UC-SDF>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "Glsl.ih"
#include "Sdf.ih"

#include <ospray/SDK/common/Model.ih>

// -----------------------------------------------------------------------------
// Geometry
// -----------------------------------------------------------------------------

inline float sdCappedCone(const vec3f& p, const vec3f& c)
{
    vec3f q = make_vec3f(length(make_vec3f(p.x, p.z, 0.f)), p.y, 0.f);
    vec3f v = make_vec3f(c.z * c.y / c.x, -c.z, 0.f);
    vec3f w = v - q;
    vec3f vv = make_vec3f(dot(v, v), v.x * v.x, 0.f);
    vec3f qv = make_vec3f(dot(v, w), v.x * w.x, 0.f);
    vec3f d = max(qv, make_vec3f(0.f)) * qv / vv;
    return sqrt(dot(w, w) - max(d.x, d.y)) *
           sign(max(q.y * v.x - q.x * v.y, w.y));
}

inline float sdTorus(const vec3f& p, const vec3f& t)
{
    vec3f q = make_vec3f(length(make_vec3f(p.x, p.z, 0.f)) - t.x, p.y, 0.f);
    return length(q) - t.y;
}

inline float sdBox(const vec3f& p, const vec3f& b)
{
    const vec3f di = abs(p) - b;
    const float mc = maxcomp(di);
    return min(mc, length(max(di, make_vec3f(0.f))));
}

inline float sdSphere(const vec3f& p, const vec3f& s)
{
    return length(p) - s.x;
}

inline float sdCapsule(const vec3f& p, const vec3f& a, const vec3f& b, float r)
{
    const vec3f pa = p - a, ba = b - a;
    const float h = clamp(dot(pa, ba) / dot(ba, ba), 0.f, 1.f);
    return length(pa - ba * h) - r;
}

inline float sdEquilateralTriangle(const vec2f& p)
{
    vec3f point = make_vec3f(p.x, p.y, 0.f);
    const float k = 1.73205f;
    point.x = abs(point.x) - 1.f;
    point.y = point.y + 1.f / k;
    if (point.x + k * point.y > 0.f)
        point = make_vec3f(point.x - k * point.y, -k * point.x - point.y, 0.f) /
                2.f;
    point.x += 2.0 - 2.0 * clamp((point.x + 2.0) / 2.0, 0.0, 1.0);
    return -length(point) * sign(point.y);
}

inline float sdTriPrism(const vec3f& p, const vec2f& h)
{
    vec3f q = abs(p);
    const float d1 = q.z - h.y;
    const float d2 = max(q.x * 0.866025f + p.y * 0.5f, -p.y) - h.x * 0.5f;
    return length(max(make_vec3f(d1, d2, 0.f), make_vec3f(0.f))) +
           min(max(d1, d2), 0.f);
}

inline float sdCylinder(const vec3f& p, const vec3f& h)
{
    const vec3f a = make_vec3f(p.x, p.z, 0.f);
    const vec3f b = make_vec3f(length(a), p.y, 0.f);
    const vec3f c = b - make_vec3f(h.x, h.y, 0.f);
    const vec3f d = abs(max(c, make_vec3f(0.f)));
    return min(max(d.x, d.y), 0.f) + length(d);
}

inline float udRoundBox(const vec3f& p, const vec3f& b, float r)
{
    return length(max(abs(p) - b, make_vec3f(0.f))) - r;
}

inline float sdEllipsoid(const vec3f& p, const vec3f& r)
{
    return (length(p / r) - 1.f) * min(min(r.x, r.y), r.z);
}

inline float length8(const vec2f& v)
{
    vec2f p = v;
    p = p * p;
    p = p * p;
    p = p * p;
    return pow(p.x + p.y, 1.f / 8.f);
}

inline float sdTorus82(const vec3f& p, const vec2f& t)
{
    const vec2f q = make_vec2f(length(make_vec3f(p.x, p.z, 0.f)) - t.x, p.y);
    return length8(q) - t.y;
}

// -----------------------------------------------------------------------------
// Operations
// -----------------------------------------------------------------------------

inline float opS(const float d1, const float d2)
{
    return max(-d2, d1);
}

inline vec2f opU(const vec2f a, const vec2f b)
{
    return (a.x < b.x) ? a : b;
}

inline vec3f opRep(const vec3f& p, const vec3f& c)
{
    return mod(p, c) - 0.5f * c;
}

inline float smin(const float a, const float b, const float k)
{
    float res = exp(-k * a) + exp(-k * b);
    return -log(res) / k;
}

inline float opBlend(const float a, const float b)
{
    return smin(a, b, 5);
}

inline vec3f opTwist(const vec3f& p)
{
    const float c = cosf(p.y);
    const float s = sinf(p.y);
    const LinearSpace2f m =
        make_LinearSpace2f(make_vec2f(c, -s), make_vec2f(s, c));
    const vec2f a = m * make_vec2f(p.x, p.z);
    return make_vec3f(a.x, a.y, p.y);
}

inline float opDisplacement(const vec3f& p)
{
    return 0.1f * sin(5.f * p.x) * sin(5.f * p.y) * sin(5.f * p.z);
}

// -----------------------------------------------------------------------------
// Utils
// -----------------------------------------------------------------------------

inline float maxcomp(const vec3f& p)
{
    return max(p.x, max(p.y, p.z));
}
