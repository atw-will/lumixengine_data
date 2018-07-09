Gui.enableCursor(Gui.instance, true)
Navigation.load(g_scene_navigation, "universes/subverted.nav")
speed = 4
stopdist = 0.2
local ANIM_CONTROLLER_TYPE = Engine.getComponentType("anim_controller")
local anim_ctrl = -1
local speed_input_idx = -1

function init()
-- cache some stuff
    speed_input_idx = Animation.getControllerInputIndex(g_scene_animation, this, "speed")
end

function update(time_delta)

    -- get agent speed from navigation and set it as input to animation controller
    -- so it can play the right animation
    local agent_speed = Navigation.getAgentSpeed(g_scene_navigation, this)
    Animation.setControllerFloatInput(g_scene_animation, this, speed_input_idx, agent_speed)

end


