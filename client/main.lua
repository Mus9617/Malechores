local coordsActivas = nil -- Almacena las coordenadas activas
local lastKnownCoords = nil -- Almacena la última posición conocida
local G_KEY = 0x760A9C6F -- Código hexadecimal para la tecla G
local DOWN_KEY = 0x05CA7C52 -- Código hexadecimal para la tecla DOWN
local UP_KEY = 0x6319DB71   -- Código hexadecimal para la tecla UP

local activeBlips = {} -- Tabla para almacenar los blips activos
local isMenuOpen = false -- Estado del menú
local coordenadasBloqueadas = false -- Estado para bloquear fijación de coordenadas

-- Guardar coordenadas y actualizar última posición conocida
RegisterNetEvent("malechores:guardarCoords")
AddEventHandler("malechores:guardarCoords", function(coords)
    if coordsActivas then
        lastKnownCoords = coordsActivas -- Guardar las coordenadas actuales como última posición conocida
    end
    coordsActivas = coords
    print("Coordenadas guardadas:", coords.x, coords.y, coords.z)
end)

-- Crear blips temporales
Citizen.CreateThread(function()
    print("Esperando tecla DOWN para fijar coordenadas con un blip...")
    while true do
        Citizen.Wait(0)
        if not coordenadasBloqueadas and IsControlJustReleased(0, DOWN_KEY) then
            if coordsActivas then
                local x = coordsActivas.x
                local y = coordsActivas.y
                local z = coordsActivas.z

                local newBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z) -- Crear blip
                Citizen.InvokeNative(0x662D364ABF16DE2F, newBlip, 1) -- Configurar blip visible
                table.insert(activeBlips, newBlip)

                -- Eliminar el blip automáticamente después de 10 minutos
                Citizen.SetTimeout(600000, function() -- 10 minutos
                    if DoesBlipExist(newBlip) then
                        RemoveBlip(newBlip) -- Usar la native correcta para eliminar blips
                        print("Blip eliminado automáticamente tras 10 minutos.")
                    end
                end)
            else
                print("No hay coordenadas activas para crear un blip.")
            end
        elseif coordenadasBloqueadas and IsControlJustReleased(0, DOWN_KEY) then
            TriggerEvent("bln_notify:send", {
                title = "Acción no Permitida",
                description = "No puedes fijar coordenadas del sospechoso desaparecido. Mira los últimos avisos.",
                icon = "error",
                placement = "middle-right",
                duration = 8000
            })
            print("Intento de fijar coordenadas bloqueado.")
        end
    end
end)

-- Nueva combinación para borrar todos los blips manualmente
Citizen.CreateThread(function()
    print("Esperando tecla UP para borrar todos los blips...")
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, UP_KEY) then
            print("Tecla UP detectada - Eliminando todos los blips activos.")
            for _, blip in ipairs(activeBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip) -- Usar RemoveBlip para asegurarnos de que se eliminen
                end
            end
            activeBlips = {} -- Limpiar la lista de blips
            print("Todos los blips han sido eliminados.")
        end
    end
end)

-- Eliminar todos los blips al finalizar el rol
RegisterNetEvent("malechores:finalizarRol")
AddEventHandler("malechores:finalizarRol", function()
    print("Finalizando rol, eliminando todos los blips activos.")
    for _, blip in ipairs(activeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip) -- Usar RemoveBlip para eliminar blips
        end
    end
    activeBlips = {} -- Limpiar la lista de blips
    print("Todos los blips han sido eliminados automáticamente.")
end)

-- Bloquear coordenadas al desaparecer el sospechoso
RegisterNetEvent("malechores:bloquearCoords")
AddEventHandler("malechores:bloquearCoords", function()
    coordenadasBloqueadas = true
    print("Fijación de coordenadas bloqueada por desaparición del sospechoso.")
end)

-- Obtener última posición conocida y enviar notificación
RegisterNetEvent("malechores:ultimaPosicionConocida")
AddEventHandler("malechores:ultimaPosicionConocida", function()
    if lastKnownCoords then
        print("Última posición conocida:", lastKnownCoords.x, lastKnownCoords.y, lastKnownCoords.z)
        TriggerEvent("bln_notify:send", {
            title = "Última Posición Conocida",
            description = string.format(
                "El sospechoso fue visto por última vez en las coordenadas: %.2f, %.2f.",
                lastKnownCoords.x, lastKnownCoords.y
            ),
            icon = "info",
            placement = "middle-right",
            duration = 10000
        })
    else
        print("No hay última posición conocida disponible.")
    end
end)

-- Abrir o cerrar la interfaz NUI
RegisterNUICallback("sendTestigo", function(data)
    TriggerServerEvent("server:realizarTirada", data) -- Enviar datos al servidor
end)

-- Alternar el menú NUI
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    SetNuiFocus(isMenuOpen, isMenuOpen)
    SendNUIMessage({ action = isMenuOpen and "open" or "close" })
    print(isMenuOpen and "Menú abierto" or "Menú cerrado") -- Depuración
end

-- Callback de NUI para enviar datos al servidor
RegisterNUICallback("sendTestigo", function(data, cb)
    print("Enviando testigo al servidor...")
    TriggerServerEvent("server:realizarTirada")
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb("ok")
end)

-- Callback de NUI para cerrar el menú
RegisterNUICallback("closeUI", function(data, cb)
    print("Cerrando menú NUI...")
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb("ok")
end)

-- Hilo principal para capturar la tecla G (usada para abrir el menú)
Citizen.CreateThread(function()
    print("Esperando tecla G para alternar el menú...")
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, G_KEY) then
            print("Tecla G detectada - Alternando menú")
            toggleMenu()
        end
    end
end)

-- Comando para fijar un waypoint manualmente
RegisterCommand("settestwaypoint", function(source, args, rawCommand)
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    if x and y then
        -- Eliminar cualquier waypoint existente
        Citizen.InvokeNative(0xD8E694757BCEA8E9) -- SetWaypointOff()
        -- Fijar el nuevo waypoint
        Citizen.InvokeNative(0x8FBFD2AEB196B369, x, y) -- SetNewWaypoint(float x, float y)
        print("Waypoint forzado en:", x, y)
    else
        print("Error: Coordenadas inválidas.")
    end
end, false)
