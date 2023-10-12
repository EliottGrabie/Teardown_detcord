--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html

function init()

  detcord_group = 4
  
  cableStart = nil
  cableEnd = nil
  soundError = LoadSound('error.ogg')
  soundStart = LoadSound('grab0.ogg')
  soundEnd = LoadSound('grab3.ogg')
  soundCould = LoadSound('grab2.ogg')
  errorPress = false
  couldPlace = false
  placeDistance = 10
  cableStrength = 1
  minimumLength = 0.1
  
  cableStyles = 
    {
      name="Red",
      color="1 0.05 0.05",
      rgb={1,0.05,0.05},
      path="MOD/vox/detcord_red.vox"
    }
  
  RegisterTool("detcord", "Det Cord", cableStyles.path, detcord_group)

  SetBool("game.tool.detcord.enabled", true)
  
  Cords = {}
  
  lPosExplode = {}
  explotionKeyPressed = false
  explosiontForce = 0.5

  speedExplosionSetting = 1
  speedExplosionTempo = 1

end

function tick(dt)
	--DebugWatch('tick : ' .. dt)

	if GetString("game.player.tool") == "detcord" then
		if GetBool("game.player.canusetool") then
			if InputDown("lmb") and not cableStart and not errorPress then
				local t = GetCameraTransform()
				local dir = TransformToParentVec(t, Vec(0, 0, - 1))
				local hit, dist, normal, shape = QueryRaycast(t.pos, dir, placeDistance)
				if hit then
					local hitpoint = VecAdd(t.pos, VecScale(dir, dist))
					cableStart = hitpoint
					PlaySound(soundStart)
					couldPlace = true
				else
					PlaySound(soundError)
					errorPress = true
				end
			end
			if InputReleased("lmb") then
				errorPress = false
				local t = GetCameraTransform()
				local dir = TransformToParentVec(t, Vec(0, 0, - 1))
				local hit, dist, normal, shape = QueryRaycast(t.pos, dir, placeDistance)
				if cableStart and hit then
					local hitpoint = VecAdd(t.pos, VecScale(dir, dist))
					cableEnd = hitpoint
					local length = VecLength(VecSub(cableStart,cableEnd))
					if length > minimumLength then
						cable = SpawnCable(cableStart,cableEnd)
						PlaySound(soundEnd)
						--DebugPrint('lCable : ' .. #cable)
						--DebugPrint('cableStart : '..table.concat(cableStart," ")..' cableEnd : '..table.concat(cableEnd," "))
						localCableStart = TransformToLocalPoint(GetShapeWorldTransform(GetJointShapes(cable[1])[1]),cableStart)
						localCableEnd = TransformToLocalPoint(GetShapeWorldTransform(GetJointShapes(cable[1])[2]),cableEnd)
						--DebugPrint('localCableStart : '..table.concat(localCableStart," ")..' localCableEnd : '..table.concat(localCableEnd," "))
						cord = {cable[1],localCableStart,localCableEnd}
						table.insert(Cords, cord)
					else
						PlaySound(soundError)
					end
					cableStart = nil
					cableEnd = nil
					couldPlace = false
				else
					PlaySound(soundError)
					cableStart = nil
					cableEnd = nil
					couldPlace = false
				end
			end
		end

		-- afficher les target rouge pendant selection
		if cableStart and not cableEnd then
			local t = GetCameraTransform()
			local dir = TransformToParentVec(t, Vec(0, 0, - 1))
			local frontPoint = VecAdd(t.pos,VecScale(dir,3))
			local hit, dist, normal, shape = QueryRaycast(t.pos, dir, placeDistance)
				if hit then
					local hitpoint = VecAdd(t.pos, VecScale(dir, dist))
					frontPoint = hitpoint
					if not couldPlace then
						PlaySound(soundCould)
					end
					couldPlace = true
				else
					couldPlace = false
				end
      
			local style = cableStyles
      
			if couldPlace then
				DrawLine(cableStart, frontPoint, style.rgb[1], style.rgb[2], style.rgb[3], 0.5)
			else
				DrawLine(cableStart, frontPoint, style.rgb[1], style.rgb[2], style.rgb[3], 0.1)
			end
			--DebugCross(cableStart,style.rgb[1], style.rgb[2], style.rgb[3],0.5)
		end
		
		-- faire exploser
		if InputPressed("K") and #Cords > 0 then
			--DebugPrint('InputPressed(K)')
			--DebugPrint(#Cords)
			for i, cord in ipairs(Cords) do
				
				--pos fin pos debut
				firstJoint = GetJointShapes(cord[1])[1]
				t = GetShapeWorldTransform(firstJoint)
				firstTrPos = TransformToParentPoint(t,cord[2])
				--DebugPrint('firstTrPos '.. i .. ' : ' ..table.concat(firstTrPos," "))
				
				lastJoint = GetJointShapes(cord[1])[2]
				t = GetShapeWorldTransform(lastJoint)
				lastTrPos = TransformToParentPoint(t,cord[3])
				--DebugPrint('lastTrPos '.. i .. ' : ' ..table.concat(lastTrPos," "))

				vDif = VecSub(firstTrPos,lastTrPos)
				--DebugPrint('vDif '.. table.concat(vDif," "))

				--DebugPrint('VecLength '.. VecLength(vDif))
				divCord = 10.0 - (explosiontForce - 0.1) * (8.0 / 3.9)
				nbDivCord = (math.floor(VecLength(vDif)*10)) / (explosiontForce*15)
				--DebugPrint(nbDivCord..' = '..(math.floor(VecLength(vDif)*10))..' / ('.. explosiontForce*15 .. ')')
				--DebugPrint('nbDivCord '.. i .. ' : ' ..nbDivCord)
				table.insert(lPosExplode, firstTrPos)
				for i=1,nbDivCord do
					vDiv = VecScale(vDif,i/nbDivCord)
					--DebugPrint('vDiv '.. i .. ' : ' ..table.concat(vDiv," "))
					vExplode = VecSub(firstTrPos,vDiv)
					--DebugPrint('vExplode '.. i .. ' : ' ..table.concat(vExplode," "))
					table.insert(lPosExplode, vExplode)
					--DebugPrint('VecScale '.. table.concat(VecScale(vDif,i/10)," "))
				end
				table.insert(lPosExplode, lastTrPos) 

				Delete(cord[1])
	
			end
			
			--ExplosedPoint(lPosExplode)
			
			Cords = {}
			explotionKeyPressed = true
			
		end
	end
	--DebugPrint('tick : ' .. dt)
end

function SpawnCable(from,to)
  local fromString = table.concat(from," ")
  local toString = table.concat(to," ")
  local style = cableStyles
  local ropeXML = '\
  <rope color="' .. style.color .. '" slack="-0.7" strength="' .. cableStrength .. '">\
    <location rot="0.0 0.0 0.0" pos="' .. fromString .. '"/>\
    <location rot="0.0 0.0 0.0" pos="' .. toString .. '"/>\
  </rope>'
  return Spawn(ropeXML,Transform(),false,true)
end

--unused
function ExplosedPoint(posExplode)
	if explosiontForce < 0.5 then
		holeSize = explosiontForce*2
		MakeHole(posExplode, holeSize, holeSize/1.2, holeSize/1.5) 
		ParticleReset()
		ParticleType("smoke")
		ParticleRadius(0.5)
		SpawnParticle(posExplode, VecSub(Vec(0, 0, 0), VecScale(posExplode, 0.2)), 0.5)
	else
		Explosion(posExplode,explosiontForce)
	end
end

function update(dt)
	--DebugWatch('update : ' .. dt)
	if explotionKeyPressed then
		if speedExplosionTempo == 1  then 
			ExplosedPoint(lPosExplode[1])
			table.remove(lPosExplode,1)
			speedExplosionTempo = speedExplosionSetting
		elseif speedExplosionTempo < 1 then
			--TO DO fast !
			if speedExplosionTempo == 0 then
				for i=1,#lPosExplode do
					ExplosedPoint(lPosExplode[1])
					table.remove(lPosExplode,1)
				end
			else
				for i=1,10-(speedExplosionSetting*10) do
					ExplosedPoint(lPosExplode[1])
					table.remove(lPosExplode,1)
				end
			end
		else
			speedExplosionTempo = speedExplosionTempo-1
		end
		
		if #lPosExplode == 0 then
			explotionKeyPressed = false
			speedExplosionTempo = speedExplosionSetting
		end
	end

end

function draw()
	if GetString("game.player.tool") == "detcord" then
		UiFont("regular.ttf", 22)
		UiTextShadow(0, 0, 0, 0.5, 0.5)
		if not uix then uix = UiWidth() - 200 end
		if not uiy then uiy = 50 end

		UiTranslate(uix, uiy)

		if InputDown("shift") then
			uiShift = true
		else
			uiShift = false
		end

		if InputDown("alt") then
			uiAlt = true
		else
			uiAlt = false
		end

		if InputPressed("shift") or InputReleased("shift") or  InputPressed("alt") or InputReleased("alt") then
			if uiShift or uiAlt then
				SetValue("uix", UiCenter()-100, "cosine", 0.25)
				SetValue("uiy", UiMiddle()-100, "cosine", 0.25)
			else
				SetValue("uix", UiWidth()-200, "cosine", 0.25)
				SetValue("uiy", 50, "cosine", 0.25)
			end
		end
		if uiShift then
			--DebugPrint('explosiontForce debut : ' .. explosiontForce)
			UiMakeInteractive()
			UiText("Scroll to change explosion strength")
			UiTranslate(0, 30)
			UiText(explosiontForce)
			explosiontForce=explosiontForce+(InputValue("mousewheel")*0.1)
			if explosiontForce < 0.1 then
				explosiontForce = 0.1
			elseif explosiontForce > 4.0 then
				explosiontForce = 4.0
			end
			--DebugPrint('explosiontForce fin : ' .. explosiontForce)
		elseif uiAlt then
			--DebugPrint('explosiontForce debut : ' .. explosiontForce)
			UiMakeInteractive()
			UiText("Scroll to change explosion speed \nLower:faster Higher:slower")
			UiTranslate(0, 50)
			UiText(speedExplosionSetting)
			--DebugPrint('InputValue("mousewheel") : ' .. InputValue("mousewheel"))
			if (speedExplosionSetting == 1 and InputValue("mousewheel") > 0) or speedExplosionSetting > 1 then
				speedExplosionSetting = math.floor(speedExplosionSetting)
				speedExplosionSetting=speedExplosionSetting+(InputValue("mousewheel")*1)
			elseif (speedExplosionSetting == 1 and InputValue("mousewheel") < 0) or speedExplosionSetting < 1 then
				speedExplosionSetting=speedExplosionSetting+(InputValue("mousewheel")*0.1)
				-- bug 1.654986456e-116
				if speedExplosionSetting < 0.1 then
					speedExplosionSetting = 0
				end
			end 
			if speedExplosionSetting < 0 then
				speedExplosionSetting = 0
			elseif speedExplosionSetting > 20 then
				speedExplosionSetting = 20
			end
			--DebugPrint('explosiontForce fin : ' .. explosiontForce) 
			speedExplosionTempo = speedExplosionSetting
		else
			UiText("Hold shift to streng \nHold alt to Speed \nk to detonate")
		end

	end
end

