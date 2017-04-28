--  ╔═══════════════════════════════╗
--  ║ » agar.io 		 	        ║
--  ║ » Project Agario              ║
--  ║ » Version: 0.0.1              ║
--  ║ » Author: INCepted			║
--  ║ » Copyright © 2017            ║
--  ╚═══════════════════════════════╝

local cClient = {};

local iSX, iSY = guiGetScreenSize();

function cClient:constructor()
	-- CLASS VARS --
	self.bInGame 			= false;
	self.tblPlayers 		= {};
	self.tblFood 			= {};
	self.tblEaten 			= {};

	self.iBaseSize 			= PLAYER_BASE_SIZE;
	self.iPixelPerSize 		= PIXEL_PER_SIZE;

	self.iFoodSize 			= FOOD_SIZE;
	--self.iMaxEatingDistance = 3;

	self.iSpeedFactor 		= MOVE_SPEED_FACTOR;

	-- SYNC --
	self.iLastRefresh 		= 0;

	-- LOCAL PLAYER --
	self.vMyPosition 		= Vector2(0,0);
	self.vCamera 			= Vector2(0,0);
	self.iZoom				= DEFAULT_CAMERA_ZOOM;

	self.tblMyData	 		= {};

	-- MAP --
	self.vMapSize 			= Vector2(MAP_SIZE[1], MAP_SIZE[2]);

	-- DX --
	self.iWidth 			= iSX;
	self.iHeight 			= iSY;
	self.iX 				= (iSX/2)-(self.iWidth/2);
	self.iY 				= (iSY/2)-(self.iHeight/2);
	self.vMiddle			= Vector2(self.iX+(self.iWidth/2), self.iY+(self.iHeight/2));

	-- BINDS --
	self.bJoin 				= bind(cClient.join, self);
	self.bPlayerJoin 		= bind(cClient.onPlayerJoin, self);
	self.bOnRender 			= bind(cClient.render, self);
	self.bRecieveFood 		= bind(cClient.onRecieveFood, self);
	self.bGetPlayers 		= bind(cClient.onRecievePlayers, self);
	self.bQuitPlayer 		= bind(cClient.onPlayerQuit, self);
	self.bOnZoomIn 			= bind(cClient.onZoomIn, self);
	self.bOnZoomOut 		= bind(cClient.onZoomOut, self);

	-- COMMANDS --
	addCommandHandler(START_COMMAND, self.bJoin);

	-- EVENTS --
	addEvent("Agario:joinPlayer", true);
	addEventHandler("Agario:joinPlayer", root, self.bPlayerJoin);

	addEvent("Agario:sendFood", true);
	addEventHandler("Agario:sendFood", root, self.bRecieveFood);

	addEvent("Agario:sendPlayerData", true);
	addEventHandler("Agario:sendPlayerData", root, self.bGetPlayers);

	addEvent("Agario:quitPlayer", true);
	addEventHandler("Agario:quitPlayer", root, self.bQuitPlayer);

	addEventHandler("onClientRender", root, self.bOnRender);

	--bindKey("mouse_wheel_up", "down", self.bOnZoomIn);
	--bindKey("mouse_wheel_down", "down", self.bOnZoomOut);
end

function cClient:onZoomIn()
	self.iZoom = self.iZoom + 0.1;
end

function cClient:onZoomOut()
	self.iZoom = self.iZoom - 0.1;
end

function cClient:sound(strName)
	return playSound("res/sounds/"..strName..".mp3");
end

function cClient:join()
	if not self.bInGame then
		localPlayer:setDimension(IDLE_DIMENSION);
		setCameraMatrix(628.89770507813, -249.42483520508, 26.195659637451, 529.04321289063, -249.91798400879, 20.826166152954);
		return triggerServerEvent("Agario:join", localPlayer);
	end
end

function cClient:onRecievePlayers(tblPlayers)
	for uPlayer in pairs(self.tblPlayers) do
		if not tblPlayers[uPlayer] then
			self.tblPlayers[uPlayer] = nil;
		end
	end

	for uPlayer, tblData in pairs(tblPlayers) do
		if (uPlayer == localPlayer) then
			self.tblMyData = tblData;
		else
			self.tblPlayers[uPlayer] = tblData;
		end
	end
end

function cClient:onRecieveFood(tblFood)
	self.tblFood = {};

	for iFood, tblData in pairs(tblFood) do
		if (tblData) then
			self.tblFood[iFood] = {
				vPosition = Vector2(tblData.tblPosition[1], tblData.tblPosition[2]),
				iValue = tblData.iValue,
				tblColor = tblData.tblColor,
			};
		end
	end
end

function cClient:onPlayerQuit(uPlayer)
	self.tblEaten[uPlayer] = nil;
	self.tblPlayers[uPlayer] = nil;
end

function cClient:onPlayerJoin(uPlayer, tblData)
	if (uPlayer == localPlayer) then
		self.bInGame = true;
		self.tblMyData = tblData;
		showCursor(true);
		self.vMyPosition = Vector2(tblData.tblPosition[1], tblData.tblPosition[2]);
	end 

	self.tblEaten[uPlayer] = nil;

	if not self.tblPlayers[uPlayer] and (uPlayer ~= localPlayer) then
		self.tblPlayers[uPlayer] = tblData;
	end	
end

function cClient:getPositionFromCoords(iX, iY)
	local iCX, iCY = self.vMiddle.x + iX, self.vMiddle.y - iY;
	return (iCX - self.vCamera.x)*self.iZoom, (iCY + self.vCamera.y)*self.iZoom;
end

function cClient:getCoordsFromPosition(iX, iY)
	local iX, iY = iX/self.iZoom, iY/self.iZoom;
	local iPX, iPY = iX - self.vMiddle.x, -(iY - self.vMiddle.y);
	return (iPX + self.vCamera.x), (iPY + self.vCamera.y);
end

function cClient:moveLocal(iX, iY)
	if (iX <= self.vMapSize.x) and (iX > -(self.vMapSize.x)) then
		self.vMyPosition.x = iX;
	end

	if (iY <= self.vMapSize.y) and (iY > -(self.vMapSize.y)) then
		self.vMyPosition.y = iY;
	end

	triggerServerEvent("Agario:move", localPlayer, self.vMyPosition.x, self.vMyPosition.y);
end

function debug(...)
	outputChatBox(...);
end

function cClient:checkEating()
	local iPlayerRadius = (self.tblMyData.iSize * self.iPixelPerSize + self.iBaseSize)/2;

	for iFood, tblData in pairs(self.tblFood) do
		local iFoodRadius = (tblData.iValue * self.iPixelPerSize + self.iFoodSize)/2;
		local iDistance = getDistanceBetweenPoints2D(tblData.vPosition.x, tblData.vPosition.y, self.vMyPosition.x, self.vMyPosition.y);

		if (iDistance <= math.max(iPlayerRadius-iFoodRadius, 1)) then
			self:eatFood(iFood);
		end
	end

	for uPlayer, tblData in pairs(self.tblPlayers) do
		if (uPlayer ~= localPlayer) then
			local iTargetRadius = (tblData.iSize * self.iPixelPerSize + self.iBaseSize)/2;
			local iDistance = getDistanceBetweenPoints2D(tblData.tblPosition[1], tblData.tblPosition[2], self.vMyPosition.x, self.vMyPosition.y);

			if (iDistance <= math.max(iPlayerRadius-iTargetRadius, 1)) then
				if (iPlayerRadius > iTargetRadius) then
					--outputChatBox((iPlayerRadius*2-iTargetRadius*2))
					--if (iPlayerRadius*2-iTargetRadius*2) > 5 then
					if (1 - (iTargetRadius/iPlayerRadius)) > MIN_EAT_PERCENTAGE then
						self:eatPlayer(uPlayer);
					end
				end
			end
		end
	end
end

function cClient:eatFood(iFood)
	if (iFood) and not self.tblEaten[iFood] then
		self:sound("plop");
		self.tblEaten[iFood] = true;
		return triggerServerEvent("Agario:eat", localPlayer, iFood);
	end
end

function cClient:eatPlayer(uPlayer)
	if (uPlayer) and not self.tblEaten[uPlayer] and uPlayer ~= localPlayer then
		self:sound("plop");
		self.tblEaten[uPlayer] = true;
		return triggerServerEvent("Agario:eat", localPlayer, uPlayer);
	end
end

function cClient:moveCamera()
	-- CURSOR --
	local iCX, iCY = getCursorPosition();
	local iCX, iCY = self:getCoordsFromPosition(iCX * iSX, iCY * iSY);

	-- MOVEMENT --
	local vDirection = new(cVector, (iCX - self.vMyPosition.x), (iCY - self.vMyPosition.y), 0);
	local vNorm = vDirection:norm() * self.iSpeedFactor;

	local iPX, iPY = self:getPositionFromCoords(self.vMyPosition.x + vNorm.X, self.vMyPosition.y + vNorm.Y);
	local vPosition = Vector2(iPX, iPY);


	local bOutside = false;
	if (vPosition.x + 200 > iSX) then
		bOutside = true;
	end

	if (vPosition.x - 200 <= 0) then
		bOutside = true;
	end

	if (vPosition.y + 200 > iSY) then
		bOutside = true;
	end

	if (vPosition.y - 200 <= 0) then
		bOutside = true;
	end

	if (bOutside) then
		self.vCamera = Vector2(self.vCamera.x + vNorm.X, self.vCamera.y + vNorm.Y);
	end
end

function cClient:isOnScreen(iX, iY)
	local iPX, iPY = self:getPositionFromCoords(iX, iY);

	if (iPX > iSX) then
		return false;
	end

	if (iPX < 0) then
		return false;
	end

	if (iPY < 0) then
		return false;
	end

	if (iPY > iSY) then
		return false;
	end

	return true;
end


function cClient:isOnScreenSingle(iX, iY, strAchs)
	local iPX, iPY = self:getPositionFromCoords(iX, iY);

	if (strAchs == "X") then
		if (iPX > iSX) then
			return false;
		end

		if (iPX < 0) then
			return false;
		end
	else
		if (iPY < 0) then
			return false;
		end

		if (iPY > iSY) then
			return false;
		end
	end

	return true;
end

function cClient:render()
	if (self.bInGame) then
		showCursor(true);
		setCursorAlpha(200);	
		setPlayerHudComponentVisible("all", false);

		setFPSLimit(30);

		-- BACKGROUND --
		dxDrawRectangle(self.iX, self.iY, self.iWidth, self.iHeight, tocolor(220,220,220,200));

		-- BORDER --
		if (self:isOnScreenSingle(0, -self.vMapSize.y, "Y")) then
			local iBX, iBY = self:getPositionFromCoords(-self.vMapSize.x, -self.vMapSize.y);
			dxDrawRectangle(iBX, iBY, self.vMapSize.x*2*self.iZoom, 10*self.iZoom, tocolor(20, 20, 20, 30));
		end

		if (self:isOnScreenSingle(0, self.vMapSize.y, "Y")) then
			local iBX, iBY = self:getPositionFromCoords(-self.vMapSize.x, self.vMapSize.y);
			dxDrawRectangle(iBX, iBY-(10*self.iZoom), self.vMapSize.x*2*self.iZoom, 10*self.iZoom, tocolor(20, 20, 20, 30));
		end

		if (self:isOnScreenSingle(-self.vMapSize.x, 0, "X")) then
			local iBX, iBY = self:getPositionFromCoords(-self.vMapSize.x, self.vMapSize.y);
			dxDrawRectangle(iBX, iBY, 10*self.iZoom, self.vMapSize.y*2*self.iZoom, tocolor(20, 20, 20, 30));
		end

		if (self:isOnScreenSingle(self.vMapSize.x, 0, "X")) then
			local iBX, iBY = self:getPositionFromCoords(self.vMapSize.x, self.vMapSize.y);
			dxDrawRectangle(iBX, iBY, 10*self.iZoom, self.vMapSize.y*2*self.iZoom, tocolor(20, 20, 20, 30));
		end

		-- GRID --
		local iSpace = 50;
		local iGridsX = (self.vMapSize.x*2)/50;
		local iGridsY = (self.vMapSize.y*2)/50;

		for i = 0, iGridsX, 1 do 
			if (self:isOnScreenSingle(-self.vMapSize.x+(i*iSpace), 0, "X")) then
				local iBX, iBY = self:getPositionFromCoords(-self.vMapSize.x+(i*iSpace), self.vMapSize.y);
				dxDrawRectangle(iBX, iBY, 1*self.iZoom, self.vMapSize.y*2*self.iZoom, tocolor(20, 20, 20, 30));
			end
		end

		for i = 0, iGridsY, 1 do 
			if (self:isOnScreenSingle(0, -self.vMapSize.y+(i*iSpace), "Y")) then
				local iBX, iBY = self:getPositionFromCoords(-self.vMapSize.x, -self.vMapSize.y+(i*iSpace));
				dxDrawRectangle(iBX, iBY, self.vMapSize.x*2*self.iZoom, 1*self.iZoom, tocolor(20, 20, 20, 30));
			end
		end

		-- FOOD --
		for _, tblData in pairs(self.tblFood) do
			if (self:isOnScreen(tblData.vPosition.x, tblData.vPosition.y)) then
				local iX, iY = self:getPositionFromCoords(tblData.vPosition.x, tblData.vPosition.y);
				local iSize = (self.iFoodSize + (tblData.iValue * self.iPixelPerSize))*self.iZoom;
				dxDrawImage(iX-(iSize/2), iY-(iSize/2), iSize, iSize, "res/images/player.png", 0, 0, 0, tocolor(tblData.tblColor[1], tblData.tblColor[2], tblData.tblColor[3]));
			end
		end

		-- CURSOR --
		local iCX, iCY = getCursorPosition();
		local iCX, iCY = self:getCoordsFromPosition(iCX * iSX, iCY * iSY);
		local vCursor = Vector2(iCX, iCY);

		-- MOVEMENT --
		local iPX = (vCursor.x - self.vMyPosition.x);
		local iPY = (vCursor.y - self.vMyPosition.y);

		local vDirection = new(cVector, iPX, iPY, 0);
		local vNorm = vDirection:norm() * self.iSpeedFactor;

		local iPX = self.vMyPosition.x + vNorm.X;
		local iPY = self.vMyPosition.y + vNorm.Y;

		local iPlayerRadius = (self.tblMyData.iSize * self.iPixelPerSize + self.iBaseSize)/2;

		----------------------------------
		-- DEBUG
		----------------------------------
		if (DEBUG_MODE) then
			-- CURSOR POINTER
			local iTX, iTY = self:getPositionFromCoords(vCursor.x, vCursor.y);
			dxDrawRectangle(iTX, iTY, 16, 16, tocolor(255,0,0));

			-- STEP
			local iTX, iTY = self:getPositionFromCoords(iPX, iPY);
			dxDrawRectangle(iTX, iTY, 16, 16, tocolor(0,0,255));

			-- DIRECTION
			local iTX, iTY = self:getPositionFromCoords(vDirection.X, vDirection.Y);
			dxDrawRectangle(iTX, iTY, 16, 16, tocolor(0,255,0));
		end

		----------------------------------
		-- DEBUG
		----------------------------------

		if (getDistanceBetweenPoints2D(self.vMyPosition.x, self.vMyPosition.y, vCursor.x, vCursor.y) >= iPlayerRadius/2) then
			self:moveLocal(iPX, iPY);
		end

		-- PLAYERS BELOW --
		for uPlayer, tblData in pairs(self.tblPlayers) do
			if (uPlayer ~= localPlayer) and tblData.iSize <= self.tblMyData.iSize then
				if (self:isOnScreen(tblData.tblPosition[1], tblData.tblPosition[2])) then
					local iPX, iPY = self:getPositionFromCoords(tblData.tblPosition[1], tblData.tblPosition[2]);
					local iSize = (self.iBaseSize + (tblData.iSize * self.iPixelPerSize))*self.iZoom;
					dxDrawImage(iPX-(iSize/2), iPY-(iSize/2), iSize, iSize, "res/images/player.png", 0, 0, 0, tocolor(tblData.tblColor[1],tblData.tblColor[2],tblData.tblColor[3]));
					dxDrawText(uPlayer:getName(), iPX, iPY, iPX, iPY, tocolor(255,255,255,255), math.min(math.max(tblData.iSize, 1)/10, 2), "default-bold", "center", "center", false, true);
				end
			end
		end

		-- PLAYER --
		local iPX, iPY = self:getPositionFromCoords(self.vMyPosition.x, self.vMyPosition.y);
		local iSize = (self.iBaseSize + (self.tblMyData.iSize * self.iPixelPerSize))*self.iZoom;
		dxDrawImage(iPX-(iSize/2), iPY-(iSize/2), iSize, iSize, "res/images/player.png", 0, 0, 0, tocolor(self.tblMyData.tblColor[1],self.tblMyData.tblColor[2],self.tblMyData.tblColor[3]));
		dxDrawText(localPlayer:getName(), iPX, iPY, iPX, iPY, tocolor(255,255,255,255), math.min(math.max(self.tblMyData.iSize, 1)/10, 2), "default-bold", "center", "center", false, true);

		-- PLAYERS ABOVE --
		for uPlayer, tblData in pairs(self.tblPlayers) do
			if (uPlayer ~= localPlayer) and tblData.iSize > self.tblMyData.iSize then
				if (self:isOnScreen(tblData.tblPosition[1], tblData.tblPosition[2])) then
					local iPX, iPY = self:getPositionFromCoords(tblData.tblPosition[1], tblData.tblPosition[2]);
					local iSize = (self.iBaseSize + (tblData.iSize * self.iPixelPerSize))*self.iZoom;
					dxDrawImage(iPX-(iSize/2), iPY-(iSize/2), iSize, iSize, "res/images/player.png", 0, 0, 0, tocolor(tblData.tblColor[1],tblData.tblColor[2],tblData.tblColor[3]));
					dxDrawText(uPlayer:getName(), iPX, iPY, iPX, iPY, tocolor(255,255,255,255), math.min(math.max(tblData.iSize, 1)/10, 2), "default-bold", "center", "center", false, true);
				end
			end
		end

		-- EATING --
		self:checkEating();

		-- SCORE --
		dxDrawRectangle(20, iSY-70, 200, 50, tocolor(10, 10, 10, 180));
		dxDrawText("Score: "..math.floor(self.tblMyData.iSize*10), 30, iSY-70, 330, iSY-20, tocolor(240,240,240), 2, "default-bold", "left", "center");

		-- TOP LIST --
		local tblTopList = {};
		
		for uPlayer, tblData in pairs(self.tblPlayers) do
			table.insert(tblTopList, {
				strName = uPlayer:getName(),
				iScore = math.floor(10*tblData.iSize),
				tblColor = tblData.tblColor,
			});
		end

		table.insert(tblTopList, {
			strName = localPlayer:getName(),
			iScore = math.floor(10*self.tblMyData.iSize),
			tblColor = self.tblMyData.tblColor,
		});

		table.sort(tblTopList, function(a,b)
			return a.iScore > b.iScore;
		end);

		local iItems = math.min(table.count(tblTopList), MAX_PLAYER_TOPLIST);

		dxDrawRectangle(iSX - 220, 20, 200, 60 + iItems*25, tocolor(10, 10, 10, 180));
		dxDrawText("Toplist", iSX-220, 20, iSX-20, 60, tocolor(240,240,240), 2, "default-bold", "center", "center");

		local iDrawed = 0;
		for uPlayer, tblData in ipairs(tblTopList) do
			if iDrawed < MAX_PLAYER_TOPLIST then
				dxDrawText(tblData.strName, iSX-200, 60 + iDrawed * 25, iSX-20, 85 + iDrawed * 25, tocolor(tblData.tblColor[1],tblData.tblColor[2],tblData.tblColor[3]), 1, "default-bold", "left", "center");
				dxDrawText(tblData.strName, iSX-200, 60 + iDrawed * 25, iSX-20, 85 + iDrawed * 25, tocolor(255,255,255,50), 1, "default-bold", "left", "center");
				dxDrawText(math.floor(tblData.iScore), iSX-220, 60 + iDrawed * 25, iSX-40, 85 + iDrawed * 25, tocolor(240,240,240), 1, "default-bold", "right", "center");
				iDrawed = iDrawed + 1;
			else	
				break;
			end
		end

		-- CAMERA --
		self.vCamera = self.vMyPosition;
		--self:moveCamera(); -- OLD METHOD // CAMERA FOLLOWS PLAYER NOW

		-- ZOOM --
		self.iZoom = math.max(1-((math.max(self.tblMyData.iSize / 10,1)-1)/100), 0.1);
	end
end

new(cClient);
