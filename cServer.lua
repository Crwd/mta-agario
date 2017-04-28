--  ╔═══════════════════════════════╗
--  ║ » agar.io 		 	        ║
--  ║ » Project Agario              ║
--  ║ » Version: 0.0.1              ║
--  ║ » Author: INCepted			║
--  ║ » Copyright © 2017            ║
--  ╚═══════════════════════════════╝

local cServer = {};

function cServer:constructor()
	-- CLASS VARS --
	self.tblPlayers 		= {};
	self.tblFood 			= {};

	-- FOOD SETTINGS --
	self.iFoodID 			= 1;
	self.vFoodRange 		= Vector2(FOOD_RANGE[1], FOOD_RANGE[2]);

	self.iMaxFood 			= MAX_FOOD_ITEMS;

	-- BINDS --
	self.bPlayerJoin		= bind(cServer.onPlayerJoin, self);
	self.bOnEat 			= bind(cServer.onEat, self);
	self.bOnMove 			= bind(cServer.onPlayerMove, self);

	-- EVENTS --
	addEvent("Agario:join", true);
	addEventHandler("Agario:join", root, self.bPlayerJoin);

	addEvent("Agario:eat", true);
	addEventHandler("Agario:eat", root, self.bOnEat);

	addEvent("Agario:move", true);
	addEventHandler("Agario:move", root, self.bOnMove);

	-- SETUP --
	self:setup();
end

function cServer:onPlayerMove(iX, iY)
	if (client) and self.tblPlayers[client] then
		self.tblPlayers[client].tblPosition = {iX, iY};
		self:refreshPlayers();
	end
end

function cServer:addFood()
	self.tblFood[self.iFoodID] = {
		tblPosition = {math.random(-self.vFoodRange.x, self.vFoodRange.x), math.random(-self.vFoodRange.y, self.vFoodRange.y)},	
		iValue = math.random(1,5),
		tblColor = {math.random(0,255), math.random(0,255), math.random(0,255)},
	};

	self.iFoodID = self.iFoodID + 1;
end

function cServer:setup()
	for i = 1, self.iMaxFood, 1 do
		self:addFood();
	end
end

function cServer:onPlayerJoin()
	if (client) and not self.tblPlayers[client] then
		self.tblPlayers[client] = {
			tblPosition = {math.random(-SPAWN_AREA[1], SPAWN_AREA[1]), math.random(-SPAWN_AREA[2], SPAWN_AREA[2])},
			tblColor = {math.random(0,255), math.random(0,255), math.random(0,255)},
			iSize = 0,
		};

		triggerClientEvent(getRootElement(), "Agario:joinPlayer", getRootElement(), client, self.tblPlayers[client]);

		client:triggerEvent("Agario:sendFood", client, self.tblFood);
	end
end

function cServer:quitPlayer(uPlayer)
	self.tblPlayers[uPlayer] = nil;
	self:refreshPlayers();

	triggerClientEvent(getRootElement(), "Agario:quitPlayer", getRootElement(), uPlayer);
end

function cServer:joinPlayer(uPlayer)
	self.tblPlayers[uPlayer] = nil;

	self.tblPlayers[uPlayer] = {
		tblPosition = {math.random(-SPAWN_AREA[1], SPAWN_AREA[1]), math.random(-SPAWN_AREA[2], SPAWN_AREA[2])},
		tblColor = {math.random(0,255), math.random(0,255), math.random(0,255)},
		iSize = 0,
	};

	self:refreshPlayers();

	triggerClientEvent(getRootElement(), "Agario:joinPlayer", getRootElement(), uPlayer, self.tblPlayers[uPlayer]);

	uPlayer:triggerEvent("Agario:sendFood", uPlayer, self.tblFood);
end

function cServer:refreshFood()
	triggerClientEvent(getRootElement(), "Agario:sendFood", getRootElement(), self.tblFood);
end

function cServer:refreshPlayers()
	triggerClientEvent(getRootElement(), "Agario:sendPlayerData", getRootElement(), self.tblPlayers);
end

function cServer:onEat(iFood)
	if (client) and self.tblPlayers[client] then
		if (self.tblPlayers[iFood]) then
			local iPlayerSize = self.tblPlayers[client].iSize;
			local iFoodSize = self.tblPlayers[iFood].iSize;

			self.tblPlayers[client].iSize = iPlayerSize + iFoodSize;

			self:quitPlayer(iFood);
			self:joinPlayer(iFood);

			self:refreshPlayers();
		end

		if (self.tblFood[iFood]) then
			local tblFood = self.tblFood[iFood];
			local iSize = self.tblPlayers[client].iSize;

			self.tblFood[iFood] = nil;

			self.tblPlayers[client].iSize = iSize + math.max(tblFood.iValue * 1/math.max(iSize,1), 0.05);

			self:refreshPlayers();
			self:refreshFood();

			self:addFood();
		end
	end
end

new(cServer);
