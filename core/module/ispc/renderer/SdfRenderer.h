/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
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

#pragma once

#include <ospray/SDK/render/Renderer.h>

namespace sdf
{
using namespace ospray;
class SdfRenderer : public Renderer
{
public:
    SdfRenderer();

    /**
       Returns the class name as a string
       @return string containing the full name of the class
    */
    std::string toString() const final { return "SdfRenderer"; }
    void commit() final;

private:
    std::vector<void*> _lightArray;
    void** _lightPtr;

    Model* _world;
    Data* _lightData;

    ospray::vec3f _bgColor;
    float _shadows;
    float _softShadows;
    bool _shadingEnabled;
    float _timestamp;
    int _spp;

    // Fractals
    int32 _samplesPerRay;
    int32 _nbIterations;
};
} // namespace sdf
