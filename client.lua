local Radio = {
	Has = false,
	Open = false,
	On = false,
	Enabled = true,
	Handle = nil,
	Prop = `prop_cs_hand_radio`,
	Bone = 28422,
	Offset = vector3(0.0, 0.0, 0.0),
	Rotation = vector3(0.0, 0.0, 0.0),
	Dictionary = {
		"cellphone@",
		"cellphone@in_car@ds",
		"cellphone@str",
		"random@arrests",
	},
	Animation = {
		"cellphone_text_in",
		"cellphone_text_out",
		"cellphone_call_listen_a",
		"generic_radio_chatter",
	},
	Clicks = true, -- Cliques de rádio
}
Radio.Labels = {
	{ "FRZL_RADIO_HELP", "~s~" .. (radioConfig.Controls.Secondary.Enabled and "~" .. radioConfig.Controls.Secondary.Name .. "~ + ~" .. radioConfig.Controls.Activator.Name .. "~" or "~" .. radioConfig.Controls.Activator.Name .. "~") .. " para ocultar.~n~~" .. radioConfig.Controls.Toggle.Name .. "~ para ligar o rádio ~g~on~s~.~n~~" .. radioConfig.Controls.Decrease.Name .. "~ ou ~" .. radioConfig.Controls.Increase.Name .. "~ para mudar frequência~n~~" .. radioConfig.Controls.Input.Name .. "~ escolher frequência~n~~" .. radioConfig.Controls.ToggleClicks.Name .. "~ para ~a~ cliques de microfone ~n~Frequência: ~1~ MHz" },
	{ "FRZL_RADIO_HELP2", "~s~" .. (radioConfig.Controls.Secondary.Enabled and "~" .. radioConfig.Controls.Secondary.Name .. "~ + ~" .. radioConfig.Controls.Activator.Name .. "~" or "~" .. radioConfig.Controls.Activator.Name .. "~") .. " para ocultar.~n~~" .. radioConfig.Controls.Toggle.Name .. "~ para ligar o rádio ~r~off~s~.~n~~" .. radioConfig.Controls.Broadcast.Name .. "~ para transmitir.~n~Frequência: ~1~ MHz" },
	{ "FRZL_RADIO_INPUT", "Inserir Frequência" },
}
Radio.Commands = {
	{
		Enabled = true, -- Adicione um comando para poder abrir / fechar o rádio
		Name = "radio", -- Nome do comando
		Help = "Alternar rádio manual", -- Ajuda de comando mostrada na caixa de bate-papo ao digitar o comando
		Params = {},
		Handler = function(src, args, raw)
			local playerPed = PlayerPedId()
			local isFalling = IsPedFalling(playerPed)
			local isDead = IsEntityDead(playerPed)

			if not isFalling and Radio.Enabled and Radio.Has and not isDead then
				Radio:Toggle(not Radio.Open)
			elseif (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
				Radio:Toggle(false)
				Radio.On = false
				Radio:Remove()
				exports["esx_mumble"]:SetMumbleProperty("radioEnabled", false)
			elseif Radio.Open and isFalling then
				Radio:Toggle(false)
			end
		end,
	},
	{
		Enabled = true, -- Adicione um comando para escolher a frequência de rádio
		Name = "frequencia", -- Nome do comando
		Help = "Alterar frequência de rádio", -- Ajuda de comando mostrada na caixa de bate-papo ao digitar o comando
		Params = {
			{name = "number", "Digite a frequência"}
		},
		Handler = function(src, args, raw)
			if Radio.Has then
				if args[1] then
					local newFrequency = tonumber(args[1])
					if newFrequency then
						local minFrequency = radioConfig.Frequency.List[1]
						if newFrequency >= minFrequency and newFrequency <= radioConfig.Frequency.List[#radioConfig.Frequency.List] and newFrequency == math.floor(newFrequency) then
							if not radioConfig.Frequency.Private[newFrequency] or radioConfig.Frequency.Access[newFrequency] then
								local idx = nil

								for i = 1, #radioConfig.Frequency.List do
									if radioConfig.Frequency.List[i] == newFrequency then
										idx = i
										break
									end
								end

								if idx ~= nil then
									if Radio.Enabled then
										Radio:Remove()
									end

									radioConfig.Frequency.CurrentIndex = idx
									radioConfig.Frequency.Current = newFrequency

									if Radio.On then
										Radio:Add(radioConfig.Frequency.Current)
									end
								end
							end
						end
					end
				end
			end
		end,
	},
}

-- Configure cada comando de rádio, se ativado
for i = 1, #Radio.Commands do
	if Radio.Commands[i].Enabled then
		RegisterCommand(Radio.Commands[i].Name, Radio.Commands[i].Handler, false)
		TriggerEvent("chat:addSuggestion", "/" .. Radio.Commands[i].Name, Radio.Commands[i].Help, Radio.Commands[i].Params)
	end
end

-- Criar / destruir objeto de rádio portátil
function Radio:Toggle(toggle)
	local playerPed = PlayerPedId()
	local count = 0

	if not self.Has or IsEntityDead(playerPed) then
		self.Open = false

		DetachEntity(self.Handle, true, false)
		DeleteEntity(self.Handle)

		return
	end

	if self.Open == toggle then
		return
	end

	self.Open = toggle

	if self.On and not radioConfig.AllowRadioWhenClosed then
		exports["esx_mumble"]:SetMumbleProperty("radioEnabled", toggle)
	end

	local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
	local animationType = 1 + (self.Open and 0 or 1)
	local dictionary = self.Dictionary[dictionaryType]
	local animation = self.Animation[animationType]

	RequestAnimDict(dictionary)

	while not HasAnimDictLoaded(dictionary) do
		Citizen.Wait(150)
	end

	if self.Open then
		RequestModel(self.Prop)

		while not HasModelLoaded(self.Prop) do
			Citizen.Wait(150)
		end

		self.Handle = CreateObject(self.Prop, 0.0, 0.0, 0.0, true, true, false)

		local bone = GetPedBoneIndex(playerPed, self.Bone)

		SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
		AttachEntityToEntity(self.Handle, playerPed, bone, self.Offset.x, self.Offset.y, self.Offset.z, self.Rotation.x, self.Rotation.y, self.Rotation.z, true, false, false, false, 2, true)

		SetModelAsNoLongerNeeded(self.Handle)

		TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)
	else
		TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)

		Citizen.Wait(700)

		StopAnimTask(playerPed, dictionary, animation, 1.0)

		NetworkRequestControlOfEntity(self.Handle)

		while not NetworkHasControlOfEntity(self.Handle) and count < 5000 do
			Citizen.Wait(0)
			count = count + 1
		end

		DetachEntity(self.Handle, true, false)
		DeleteEntity(self.Handle)
	end
end

-- Adicionar player ao canal de rádio
function Radio:Add(id)
	exports["esx_mumble"]:SetRadioChannel(id)
end

-- Remova o player do canal de rádio
function Radio:Remove()
	exports["esx_mumble"]:SetRadioChannel(0)
end

-- Aumentar a frequência de rádio
function Radio:Decrease()
	if self.On then
		if radioConfig.Frequency.CurrentIndex - 1 < 1 and radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex] == radioConfig.Frequency.Current then
			self:Remove(radioConfig.Frequency.Current)
			radioConfig.Frequency.CurrentIndex = #radioConfig.Frequency.List
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
			self:Add(radioConfig.Frequency.Current)
		elseif radioConfig.Frequency.CurrentIndex - 1 < 1 and radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex] ~= radioConfig.Frequency.Current then
			self:Remove(radioConfig.Frequency.Current)
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
			self:Add(radioConfig.Frequency.Current)
		else
			self:Remove(radioConfig.Frequency.Current)
			radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex - 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
			self:Add(radioConfig.Frequency.Current)
		end
	else
		if radioConfig.Frequency.CurrentIndex - 1 < 1 and radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex] == radioConfig.Frequency.Current then
			radioConfig.Frequency.CurrentIndex = #radioConfig.Frequency.List
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		elseif radioConfig.Frequency.CurrentIndex - 1 < 1 and radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex] ~= radioConfig.Frequency.Current then
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		else
			radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex - 1

			if radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex] == radioConfig.Frequency.Current then
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex - 1
			end

			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		end
	end
end

-- Diminuir a frequência de rádio
function Radio:Increase()
	if self.On then
		if radioConfig.Frequency.CurrentIndex + 1 > #radioConfig.Frequency.List then
			self:Remove(radioConfig.Frequency.Current)
			radioConfig.Frequency.CurrentIndex = 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
			self:Add(radioConfig.Frequency.Current)
		else
			self:Remove(radioConfig.Frequency.Current)
			radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex + 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
			self:Add(radioConfig.Frequency.Current)
		end
	else
		if #radioConfig.Frequency.List == radioConfig.Frequency.CurrentIndex + 1 then
			if radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex + 1] == radioConfig.Frequency.Current then
				radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex + 1
			end
		end

		if radioConfig.Frequency.CurrentIndex + 1 > #radioConfig.Frequency.List then
			radioConfig.Frequency.CurrentIndex = 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		else
			radioConfig.Frequency.CurrentIndex = radioConfig.Frequency.CurrentIndex + 1
			radioConfig.Frequency.Current = radioConfig.Frequency.List[radioConfig.Frequency.CurrentIndex]
		end
	end
end

-- Gerar lista de frequências disponíveis
function GenerateFrequencyList()
	radioConfig.Frequency.List = {}

	for i = radioConfig.Frequency.Min, radioConfig.Frequency.Max do
		if not radioConfig.Frequency.Private[i] or radioConfig.Frequency.Access[i] then
			radioConfig.Frequency.List[#radioConfig.Frequency.List + 1] = i
		end
	end
end

-- Verifique se o rádio está aberto
function IsRadioOpen()
	return Radio.Open
end

-- Verifique se o rádio está ligado
function IsRadioOn()
	return Radio.On
end

-- Verifique se o jogador tem rádio
function IsRadioAvailable()
	return Radio.Has
end

-- Verifique se o rádio está ativado ou não
function IsRadioEnabled()
	return not Radio.Enabled
end

-- Verifique se o rádio pode ser usado
function CanRadioBeUsed()
	return Radio.Has and Radio.On and Radio.Enabled
end

-- Defina se o rádio está ativado ou não
function SetRadioEnabled(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end

	Radio.Enabled = value and true or false
end

-- Defina se o jogador tem um rádio ou não
function SetRadio(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end

	Radio.Has = value and true or false
end

-- Defina se o jogador tem acesso para usar o rádio quando fechado
function SetAllowRadioWhenClosed(value)
	radioConfig.Frequency.AllowRadioWhenClosed = value

	if Radio.On and not Radio.Open and radioConfig.AllowRadioWhenClosed then
		exports["esx_mumble"]:SetMumbleProperty("radioEnabled", true)
	end
end

-- Adicionar nova frequência
function AddPrivateFrequency(value)
	local frequency = tonumber(value)

	if frequency ~= nil then
		if not radioConfig.Frequency.Private[frequency] then -- Adicione apenas novas frequências
			radioConfig.Frequency.Private[frequency] = true

			GenerateFrequencyList()
		end
	end
end

-- Remover frequência privada
function RemovePrivateFrequency(value)
	local frequency = tonumber(value)

	if frequency ~= nil then
		if radioConfig.Frequency.Private[frequency] then -- Remova apenas as frequências existentes
			radioConfig.Frequency.Private[frequency] = nil

			GenerateFrequencyList()
		end
	end
end

-- Dar acesso a uma frequência
function GivePlayerAccessToFrequency(value)
	local frequency = tonumber(value)

	if frequency ~= nil then
		if radioConfig.Frequency.Private[frequency] then -- Verifique se existe frequência
			if not radioConfig.Frequency.Access[frequency] then -- Adicione apenas novas frequências
				radioConfig.Frequency.Access[frequency] = true

				GenerateFrequencyList()
			end
		end
	end
end

-- Remova o acesso a uma frequência
function RemovePlayerAccessToFrequency(value)
	local frequency = tonumber(value)

	if frequency ~= nil then
		if radioConfig.Frequency.Access[frequency] then -- Verifique se o jogador tem acesso à frequência
			radioConfig.Frequency.Access[frequency] = nil

			GenerateFrequencyList()
		end
	end
end

-- Conceda acesso a múltiplas frequências
function GivePlayerAccessToFrequencies(...)
	local frequencies = { ... }
	local newFrequencies = {}

	for i = 1, #frequencies do
		local frequency = tonumber(frequencies[i])

		if frequency ~= nil then
			if radioConfig.Frequency.Private[frequency] then -- Verifique se existe frequência
				if not radioConfig.Frequency.Access[frequency] then -- Adicione apenas novas frequências
					newFrequencies[#newFrequencies + 1] = frequency
				end
			end
		end
	end

	if #newFrequencies > 0 then
		for i = 1, #newFrequencies do
			radioConfig.Frequency.Access[newFrequencies[i]] = true
		end

		GenerateFrequencyList()
	end
end

-- Remova o acesso a várias frequências
function RemovePlayerAccessToFrequencies(...)
	local frequencies = { ... }
	local removedFrequencies = {}

	for i = 1, #frequencies do
		local frequency = tonumber(frequencies[i])

		if frequency ~= nil then
			if radioConfig.Frequency.Access[frequency] then -- Verifique se o jogador tem acesso à frequência
				removedFrequencies[#removedFrequencies + 1] = frequency
			end
		end
	end

	if #removedFrequencies > 0 then
		for i = 1, #removedFrequencies do
			radioConfig.Frequency.Access[removedFrequencies[i]] = nil
		end

		GenerateFrequencyList()
	end
end

-- Definir exportações
exports("IsRadioOpen", IsRadioOpen)
exports("IsRadioOn", IsRadioOn)
exports("IsRadioAvailable", IsRadioAvailable)
exports("IsRadioEnabled", IsRadioEnabled)
exports("CanRadioBeUsed", CanRadioBeUsed)
exports("SetRadioEnabled", SetRadioEnabled)
exports("SetRadio", SetRadio)
exports("SetAllowRadioWhenClosed", SetAllowRadioWhenClosed)
exports("AddPrivateFrequency", AddPrivateFrequency)
exports("RemovePrivateFrequency", RemovePrivateFrequency)
exports("GivePlayerAccessToFrequency", GivePlayerAccessToFrequency)
exports("RemovePlayerAccessToFrequency", RemovePlayerAccessToFrequency)
exports("GivePlayerAccessToFrequencies", GivePlayerAccessToFrequencies)
exports("RemovePlayerAccessToFrequencies", RemovePlayerAccessToFrequencies)

Citizen.CreateThread(function()
	-- Adicionar Labels
	for i = 1, #Radio.Labels do
		AddTextEntry(Radio.Labels[i][1], Radio.Labels[i][2])
	end

	GenerateFrequencyList()

	while true do
		Citizen.Wait(0)
		-- Init local vars
		local playerPed = PlayerPedId()
		local isActivatorPressed = IsControlJustPressed(0, radioConfig.Controls.Activator.Key)
		local isSecondaryPressed = (radioConfig.Controls.Secondary.Enabled == false and true or IsControlPressed(0, radioConfig.Controls.Secondary.Key))
		local isFalling = IsPedFalling(playerPed)
		local isDead = IsEntityDead(playerPed)
		local minFrequency = radioConfig.Frequency.List[1]
		local broadcastType = 3 + (radioConfig.AllowRadioWhenClosed and 1 or 0) + ((Radio.Open and radioConfig.AllowRadioWhenClosed) and -1 or 0)
		local broadcastDictionary = Radio.Dictionary[broadcastType]
		local broadcastAnimation = Radio.Animation[broadcastType]
		local isBroadcasting = IsControlPressed(0, radioConfig.Controls.Broadcast.Key)
		local isPlayingBroadcastAnim = IsEntityPlayingAnim(playerPed, broadcastDictionary, broadcastAnimation, 3)

		-- Open radio settings
		if isActivatorPressed and isSecondaryPressed and not isFalling and Radio.Enabled and Radio.Has and not isDead then
			Radio:Toggle(not Radio.Open)
		elseif (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
			Radio:Remove()
			exports["esx_mumble"]:SetMumbleProperty("radioEnabled", false)
			Radio:Toggle(false)
			Radio.On = false
		elseif Radio.Open and isFalling then
			Radio:Toggle(false)
		end

		-- Remova o player da frequência privada à qual ele não tem acesso
		if not radioConfig.Frequency.Access[radioConfig.Frequency.Current] and radioConfig.Frequency.Private[radioConfig.Frequency.Current] and Radio.On then
			Radio:Remove()
			radioConfig.Frequency.CurrentIndex = 1
			radioConfig.Frequency.Current = minFrequency
			Radio:Add(radioConfig.Frequency.Current)
		end

		-- Verifique se o jogador está segurando o rádio
		if Radio.Open then
			local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
			local openDictionary = Radio.Dictionary[dictionaryType]
			local openAnimation = Radio.Animation[1]
			local isPlayingOpenAnim = IsEntityPlayingAnim(playerPed, openDictionary, openAnimation, 3)
			local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, 1)

			-- Remova a arma na mão enquanto estamos usando o rádio
			if currentWeapon ~= `weapon_unarmed` then
				SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
			end

			-- Exibir texto de ajuda
			BeginTextCommandDisplayHelp(Radio.Labels[Radio.On and 2 or 1][1])

			if not Radio.On then
				AddTextComponentSubstringPlayerName(Radio.Clicks and "~r~desabilitar~w~" or "~g~habilitar~w~")
			end

			AddTextComponentInteger(radioConfig.Frequency.Current)
			EndTextCommandDisplayHelp(false, false, false, -1)

			-- Reproduzir animação se o jogador estiver transmitindo para o rádio
			if Radio.On then
				if isBroadcasting and not isPlayingBroadcastAnim then
					RequestAnimDict(broadcastDictionary)

					while not HasAnimDictLoaded(broadcastDictionary) do
						Citizen.Wait(150)
					end

					TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, -8, -1, 49, 0, 0, 0, 0)
				elseif not isBroadcasting and isPlayingBroadcastAnim then
					StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
				end
			end

			-- Reproduzir animação padrão se não estiver transmitindo
			if not isBroadcasting and not isPlayingOpenAnim then
				RequestAnimDict(openDictionary)

				while not HasAnimDictLoaded(openDictionary) do
					Citizen.Wait(150)
				end

				TaskPlayAnim(playerPed, openDictionary, openAnimation, 4.0, -1, -1, 50, 0, false, false, false)
			end

			-- Ligar / desligar o rádio
			if IsControlJustPressed(0, radioConfig.Controls.Toggle.Key) then
				Radio.On = not Radio.On

				exports["esx_mumble"]:SetMumbleProperty("radioEnabled", Radio.On)

				if Radio.On then
					SendNUIMessage({ sound = "audio_on", volume = 0.3})
					Radio:Add(radioConfig.Frequency.Current)
				else
					SendNUIMessage({ sound = "audio_off", volume = 0.5})
					Radio:Remove()
				end
			end

			-- Alterar frequência de rádio
			if not Radio.On then
				DisableControlAction(0, radioConfig.Controls.ToggleClicks.Key, false)

				if not radioConfig.Controls.Decrease.Pressed then
					if IsControlJustPressed(0, radioConfig.Controls.Decrease.Key) then
						radioConfig.Controls.Decrease.Pressed = true
						Citizen.CreateThread(function()
							while IsControlPressed(0, radioConfig.Controls.Decrease.Key) do
								Radio:Decrease()
								Citizen.Wait(125)
							end

							radioConfig.Controls.Decrease.Pressed = false
						end)
					end
				end

				if not radioConfig.Controls.Increase.Pressed then
					if IsControlJustPressed(0, radioConfig.Controls.Increase.Key) then
						radioConfig.Controls.Increase.Pressed = true
						Citizen.CreateThread(function()
							while IsControlPressed(0, radioConfig.Controls.Increase.Key) do
								Radio:Increase()
								Citizen.Wait(125)
							end

							radioConfig.Controls.Increase.Pressed = false
						end)
					end
				end

				if not radioConfig.Controls.Input.Pressed then
					if IsControlJustPressed(0, radioConfig.Controls.Input.Key) then
						radioConfig.Controls.Input.Pressed = true
						Citizen.CreateThread(function()
							DisplayOnscreenKeyboard(1, Radio.Labels[3][1], "", radioConfig.Frequency.Current, "", "", "", 3)

							while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
								Citizen.Wait(150)
							end

							local input = nil

							if UpdateOnscreenKeyboard() ~= 2 then
								input = GetOnscreenKeyboardResult()
							end

							Citizen.Wait(500)

							input = tonumber(input)

							if input ~= nil then
								if input >= minFrequency and input <= radioConfig.Frequency.List[#radioConfig.Frequency.List] and input == math.floor(input) then
									if not radioConfig.Frequency.Private[input] or radioConfig.Frequency.Access[input] then
										local idx = nil

										for i = 1, #radioConfig.Frequency.List do
											if radioConfig.Frequency.List[i] == input then
												idx = i
												break
											end
										end

										if idx ~= nil then
											radioConfig.Frequency.CurrentIndex = idx
											radioConfig.Frequency.Current = input
										end
									end
								end
							end

							radioConfig.Controls.Input.Pressed = false
						end)
					end
				end

				-- Ativar / desativar cliques de microfone de rádio
				if IsDisabledControlJustPressed(0, radioConfig.Controls.ToggleClicks.Key) then
					Radio.Clicks = not Radio.Clicks

					SendNUIMessage({ sound = "audio_off", volume = 0.5})

					exports["esx_mumble"]:SetMumbleProperty("micClicks", Radio.Clicks)
				end
			end
		else
			-- Reproduzir animação de rádio de serviços de emergência
			if radioConfig.AllowRadioWhenClosed then
				if Radio.Has and Radio.On and isBroadcasting and not isPlayingBroadcastAnim then
					RequestAnimDict(broadcastDictionary)

					while not HasAnimDictLoaded(broadcastDictionary) do
						Citizen.Wait(150)
					end

					TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, 0.0, -1, 49, 0, 0, 0, 0)
				elseif not isBroadcasting and isPlayingBroadcastAnim then
					StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
				end
			end
		end
	end
end)

AddEventHandler("onClientResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName and "esx_mumble" ~= resName then
		return
	end

	exports["esx_mumble"]:SetMumbleProperty("radioClickMaxChannel", radioConfig.Frequency.Max) -- Definir cliques de rádio ativados para todas as frequências de rádio
	exports["esx_mumble"]:SetMumbleProperty("radioEnabled", false) -- Desativar controle de rádio

	if Radio.Open then
		Radio:Toggle(false)
	end

	Radio.On = false
end)

RegisterNetEvent("Radio.Toggle")
AddEventHandler("Radio.Toggle", function()
	local playerPed = PlayerPedId()
	local isFalling = IsPedFalling(playerPed)
	local isDead = IsEntityDead(playerPed)

	if not isFalling and not isDead and Radio.Enabled and Radio.Has then
		Radio:Toggle(not Radio.Open)
	end
end)

RegisterNetEvent("Radio.Set")
AddEventHandler("Radio.Set", function(value)
	if type(value) == "string" then
		value = value == "true"
	elseif type(value) == "number" then
		value = value == 1
	end

	Radio.Has = value and true or false
end)
