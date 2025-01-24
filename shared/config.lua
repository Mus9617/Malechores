-- Configuración general
Config = {}

-- Ciudades con coordenadas y rangos
Config.Ciudades = {
    {nombre = "Blackwater", x = -797.12, y = -1300.05, rango = 200.0},
    {nombre = "Armadillo", x = -3683.34, y = -2609.83, rango = 200.0},
    {nombre = "Tumbleweed", x = -5508.59, y = -2941.48, rango = 200.0},
    {nombre = "Strawberry", x = -1814.01, y = -417.93, rango = 200.0},
    {nombre = "Valentine", x = -310.88, y = 785.76, rango = 200.0},
    {nombre = "Annesburg", x = 2934.34, y = 1348.65, rango = 200.0},
    {nombre = "Van Horn", x = 2971.33, y = 552.74, rango = 200.0},
    {nombre = "Saint Denis", x = 2605.87, y = -1251.92, rango = 300.0},  
    {nombre = "Rhodes", x = 1305.9, y = -1300.41, rango = 200.0}
}

-- Tiempo de enfriamiento para evitar abusos (en segundos)
Config.Cooldown = 300

-- Función para determinar si un jugador está dentro de una ciudad
function determinarCiudad(coords)
    for _, ciudad in ipairs(Config.Ciudades) do
        local distancia = math.sqrt((ciudad.x - coords.x)^2 + (ciudad.y - coords.y)^2)
        if distancia <= ciudad.rango then
            return ciudad.nombre
        end
    end
    return nil  -- Si no está en ninguna ciudad
end
