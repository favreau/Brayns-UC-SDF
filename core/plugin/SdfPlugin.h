/*
 * The SDF plug-in is a tool for scientists to extract and analyse
 * scientific data from visualization
 *
 * Copyright 2021 Blue BrainProject / EPFL
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include <plugin/api/Params.h>

#include <brayns/pluginapi/ExtensionPlugin.h>

namespace sdf
{
/**
 * @brief This class implements the SdfPlugin
 */
class SdfPlugin : public brayns::ExtensionPlugin
{
public:
    SdfPlugin();

    void init() final;

private:
    Response _getVersion() const;
};
} // namespace sdf
