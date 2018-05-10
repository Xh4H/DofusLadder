local request = require("coro-http").request

local DOFUS_URL = "https://www.dofus.com/"
local BASE_URL = DOFUS_URL .. "es/mmorpg/comunidad/directorios/paginas-personajes?TEXT=%s"
local f = string.format

local HEADERS = {
	{"user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"},
	{"accept-language", "es-ES,es;q=0.9"},
	{"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"},
	{"cookie", "__cfduid=ddc094d8a667aa4e43c3751421f3218d01522568306; LANG=es; __cfruid=2040dc9774c1c422e7b66bf15c33b8cdfe8d1c1f-1522568306; SID=3CC2243095E1544BCEF90CD92D1A0001"},
	{"upgrade-insecure-requests", "1"}
}

local function getCota(nombre)
	local cotas = {}
	local res, body = request("GET", f(BASE_URL, nombre), HEADERS)
	local subnombre = string.gsub(nombre, "%-", "%%-")

	p("Searching data for " .. args[2])

	if res.code == 200 then
		local linea

		for s in body:gmatch("[^\r\n]+") do
		   	if string.find(s, subnombre .. "<%/a%>") then linea = s end
		end

		if linea then
			local inicio, fin = string.find(linea, "%/es%/mmorpg%/comunidad%/directorios%/paginas%-personajes%/%d+%-" .. string.lower(subnombre))
			local url = string.sub(linea, inicio, fin)

			p("Profile URL found: " .. url)

			local res, body = request("GET", DOFUS_URL .. url, HEADERS)
			
			if res.code == 200 then
				local linea
				for s in body:gmatch("[^\r\n]+") do
					if string.find(s, "Cota") then linea = s end
				end
				if linea then
					local solo3v3 = linea:match("Cota de Koliseo 3v3 solo%: %<span%>%d %d+%<%/span%>")
					local team3v3 = linea:match("Cota de Koliseo 3v3 por equipos%: %<span%>%d %d+%<%/span%>")
					local solo = linea:match("Cota de Koliseo 1v1%: %<span%>%d %d+%<%/span%>")

					if solo3v3 then
						cotas["3v3solo"] = solo3v3:match("%d %d+")
					end
					if team3v3 then
						cotas["3v3team"] = team3v3:match("%d %d+")
					end
					if solo then
						cotas["1v1"] = solo:match("%d %d+")
					end
				end
			end
		end
	end

	return cotas ~= {} and cotas or nombre .. " not found."
end

if args[2] then
	coroutine.wrap(function()
		p(getCota(args[2]))
	end)()
else
	p("Please use a name.")
end
