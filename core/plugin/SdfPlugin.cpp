/*
 * The Metabolism plug-in is a tool for scientists to extract and analyse
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

#include "SdfPlugin.h"

#include <plugin/common/Logs.h>

#include <brayns/common/ActionInterface.h>
#include <brayns/engineapi/Engine.h>
#include <brayns/engineapi/Model.h>
#include <brayns/engineapi/Scene.h>
#include <brayns/parameters/ParametersManager.h>
#include <brayns/pluginapi/Plugin.h>

#include <fstream>

namespace sdf
{
const std::string PLUGIN_VERSION = "0.1.0";
const std::string PLUGIN_API_PREFIX = "sdf-";

#define CATCH_STD_EXCEPTION()                  \
    catch (const std::runtime_error &e)        \
    {                                          \
        response.status = false;               \
        response.contents = e.what();          \
        PLUGIN_ERROR << e.what() << std::endl; \
    }

void _addSdfRenderer(Engine &engine)
{
    PLUGIN_INFO("SDF renderer");
    brayns::PropertyMap properties;
    properties.setProperty({"samplesPerRay", 64, 0, 128, {"Samples per ray"}});
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty(
        {"nbIterations", 4, 1, 10, {"Number of iterations"}});
    engine.addRendererType("sdf", properties);
}

SdfPlugin::SdfPlugin()
    : ExtensionPlugin()
{
}

void SdfPlugin::init()
{
    auto actionInterface = _api->getActionInterface();
    auto &engine = _api->getEngine();

    if (actionInterface)
    {
        std::string endPoint = PLUGIN_API_PREFIX + "get-version";
        PLUGIN_INFO("Registering '" + endPoint + "' endpoint");
        actionInterface->registerRequest<Response>(endPoint, [&]()
                                                   { return _getVersion(); });
    }

    _addSdfRenderer(engine);
    _api->getParametersManager().getRenderingParameters().setCurrentRenderer(
        "sdf");
}

Response SdfPlugin::_getVersion() const
{
    Response response;
    response.contents = PLUGIN_VERSION;
    return response;
}

extern "C" ExtensionPlugin *brayns_plugin_create(int argc, char **argv)
{
    PLUGIN_INFO("Initializing SDF plug-in (version " << PLUGIN_VERSION << ")");
    PLUGIN_INFO("");

    return new SdfPlugin();
}

} // namespace sdf
