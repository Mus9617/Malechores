-- Lista de Steam IDs de policías
local listaPolicias = {
    ["steam:1100001077f813e"] = true,
    ["steam:110000140ba4d47"] = true,
    ["steam:110000102273875"] = true
}

local actualizacionesActivas = {}
local ultimoUsoTestigo = nil -- Variable para almacenar el último uso del comando de testigo
local TIEMPO_ENFRIAMIENTO = 12 * 60 -- Tiempo de enfriamiento en segundos (12 minutos)

-- Función para determinar la ciudad más cercana
function determinarCiudad(coords)
    for _, ciudad in ipairs(Config.Ciudades) do
        local distancia = math.sqrt((ciudad.x - coords.x)^2 + (ciudad.y - coords.y)^2)
        if distancia <= ciudad.rango then
            return ciudad.nombre
        end
    end
    return nil
end

-- Obtener lista de policías conectados
function obtenerPolicias()
    local policias = {}
    for _, jugadorId in ipairs(GetPlayers()) do
        local steamId = GetPlayerIdentifier(jugadorId, 0)
        if listaPolicias[steamId] then
            print("Jugador identificado como policía:", steamId)
            table.insert(policias, jugadorId)
        else
            print("Jugador no es policía:", steamId)
        end
    end
    return policias
end

-- Enviar notificación con o sin coordenadas
function enviarNotificacionConCoords(policia, titulo, mensaje, coords)
    local descripcionMensaje = coords and (mensaje .. "\n-X-.") or mensaje
    TriggerClientEvent("bln_notify:send", policia, {
        title = titulo,
        description = descripcionMensaje,
        icon = "warning",
        placement = "middle-right",
        duration = 50000
    })

    if coords then
        TriggerClientEvent("malechores:guardarCoords", policia, coords)
    end
end

-- Finalizar el rol y eliminar blips
function finalizarRolParaPolicias(policias)
    for _, policia in ipairs(policias) do
        TriggerClientEvent("malechores:finalizarRol", policia)
    end
end

-- Notificar que el sospechoso desapareció
local function notificarSospechosoDesaparecido(policias)
    local mensajeDesaparecido = "No se supo más del sospechoso. Mira los últimos avisos."
    print("El sospechoso desapareció, notificando a la policía:", mensajeDesaparecido)

    for _, policia in ipairs(policias) do
        TriggerClientEvent("bln_notify:send", policia, {
            title = "Sospechoso Desaparecido",
            description = mensajeDesaparecido,
            icon = "warning",
            placement = "middle-right",
            duration = 10000
        })

        -- Bloquear fijación de coordenadas para este evento
        TriggerClientEvent("malechores:bloquearCoords", policia)
    end
end

-- Gestionar actualizaciones del sospechoso
function enviarActualizaciones(source, descripcion)
    if actualizacionesActivas[source] then
        print("Ya hay actualizaciones activas para este jugador:", source)
        return
    end

    actualizacionesActivas[source] = {ultimoTiempo = os.time()}
    local ped = GetPlayerPed(source)
    local ultimaCoordenada = nil -- Coordenada actual
    local penultimaCoordenada = nil -- Penúltima coordenada

    Citizen.CreateThread(function()
        local policias = obtenerPolicias()
        local coords = GetEntityCoords(ped)
        ultimaCoordenada = coords

        -- Primera notificación obligatoria
        local ciudad = determinarCiudad(coords)
        local mensajeInicial = ciudad and 
            ("El sospechoso fue visto cerca de " .. ciudad) or
            string.format("El sospechoso fue visto cerca de las coordenadas: %.2f, %.2f", coords.x, coords.y)

        if descripcion and descripcion ~= "" then
            mensajeInicial = mensajeInicial .. "\nDescripción: " .. descripcion
        end

        print("Enviando primer aviso:", mensajeInicial)

        for _, policia in ipairs(policias) do
            enviarNotificacionConCoords(policia, "Sospechoso Visto", mensajeInicial, coords)
        end

        -- Intervalos de tiradas
        local intervalos = {3 * 60, 6 * 60, 10 * 60} -- Intervalos en segundos
        local inicioTiempo = os.time()

        for index, intervalo in ipairs(intervalos) do
            print(string.format("Esperando para tirada %d: %d minutos", index, intervalo / 60))
            
            -- Espera precisa basada en el tiempo actual
            while os.time() - inicioTiempo < intervalo do
                Citizen.Wait(1000) -- Verificar cada segundo
            end

            print(string.format("Iniciando tirada %d para el jugador %d", index, source))

            -- Validar si el jugador sigue conectado
            if not GetPlayerName(source) then
                print("Jugador desconectado durante las actualizaciones:", source)
                finalizarRolParaPolicias(policias)
                actualizacionesActivas[source] = nil
                return
            end

            -- Lógica de la tirada
            coords = GetEntityCoords(ped)
            penultimaCoordenada = ultimaCoordenada
            ultimaCoordenada = coords
            ciudad = determinarCiudad(coords)

            local tirada = math.random(1, 6)
            print(string.format("Tirada de dados del jugador %d: %d", source, tirada))

            if index == 1 or index == 2 then
                if tirada <= 3 then
                    local mensajeActualizacion = ciudad and 
                        ("El sospechoso pasó cerca de " .. ciudad) or
                        string.format("El sospechoso pasó cerca de las coordenadas: %.2f, %.2f", coords.x, coords.y)

                    if descripcion and descripcion ~= "" then
                        mensajeActualizacion = mensajeActualizacion .. "\nDescripción: " .. descripcion
                    end

                    print("Enviando actualización:", mensajeActualizacion)

                    for _, policia in ipairs(policias) do
                        enviarNotificacionConCoords(policia, "Actualización del Sospechoso", mensajeActualizacion, coords)
                    end
                else
                    print("Tirada fallida, no se envió actualización.")
                end
            elseif index == 3 then
                if tirada <= 3 then
                    local mensajeFinal = ciudad and 
                        ("El sospechoso pasó cerca de " .. ciudad .. ". Última posición conocida.") or
                        string.format("El sospechoso pasó cerca de las coordenadas: %.2f, %.2f. Última posición conocida.", coords.x, coords.y)

                    print("Enviando última actualización:", mensajeFinal)

                    for _, policia in ipairs(policias) do
                        enviarNotificacionConCoords(policia, "Última Actualización del Sospechoso", mensajeFinal, coords)
                    end
                else
                    -- Marcar como desaparecido y bloquear coordenadas
                    notificarSospechosoDesaparecido(policias)
                end

                -- Finalizar el rol tras la última tirada
                print("Finalizando el rol tras la última actualización.")
                finalizarRolParaPolicias(policias)
                actualizacionesActivas[source] = nil
            end
        end
    end)
end

-- Evento para realizar tiradas con enfriamiento
RegisterNetEvent("server:realizarTirada")
AddEventHandler("server:realizarTirada", function(data)
    local source = source
    local descripcion = data.descripcion or ""
    local tiempoActual = os.time()

    -- Verificar si ya está en enfriamiento
    if ultimoUsoTestigo and (tiempoActual - ultimoUsoTestigo) < TIEMPO_ENFRIAMIENTO then
        local tiempoRestante = TIEMPO_ENFRIAMIENTO - (tiempoActual - ultimoUsoTestigo)
        local minutosRestantes = math.floor(tiempoRestante / 60)
        local segundosRestantes = tiempoRestante % 60

        -- Notificar al jugador que no puede usarlo aún
        TriggerClientEvent("bln_notify:send", source, {
            title = "Enfriamiento Activo",
            description = string.format("Debes esperar %d minutos y %d segundos antes de usar el comando de testigo nuevamente.", minutosRestantes, segundosRestantes),
            icon = "error",
            placement = "middle-right",
            duration = 8000
        })

        print(string.format("Jugador %d intentó usar el comando de testigo en enfriamiento. Tiempo restante: %d minutos %d segundos.", source, minutosRestantes, segundosRestantes))
        return
    end

    -- Actualizar el tiempo del último uso y permitir la acción
    ultimoUsoTestigo = tiempoActual
    print("Evento 'server:realizarTirada' recibido de:", source)
    enviarActualizaciones(source, descripcion)
end)
