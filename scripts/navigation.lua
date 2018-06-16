Gui.enableCursor(Gui.instance, true)
Navigation.load(g_scene_navigation, "universes/subverted.nav")
speed = 5
stopdist = 0.2


function onInputEvent(event)
if event.type == Engine.INPUT_EVENT_BUTTON then
    if event.device.type == Engine.INPUT_DEVICE_MOUSE then
        if event.key_id == 1 then
            local is_hit, pos = Renderer.castCameraRay(g_scene_renderer, "main", event.x_abs, event.y_abs)
            if is_hit then
                Navigation.navigate(g_scene_navigation, this, pos, speed, stopdist)
            end
        end
    end
end
end