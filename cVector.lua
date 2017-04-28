--  ╔═══════════════════════════════╗
--  ║ » agar.io 		 	        ║
--  ║ » Project Agario              ║
--  ║ » Version: 0.0.1              ║
--  ║ » Author: INCepted			║
--  ║ » Copyright © 2017            ║
--  ╚═══════════════════════════════╝

cVector = {}

function Vector(...)
	return new(cVector, ...);
end

function cVector:constructor(x, y, z)
	if tonumber(x) and tonumber(y) and tonumber(z) then
		self.X, self.Y, self.Z = tonumber(x), tonumber(y), tonumber(z)
	else
		self.X, self.Y, self.Z = 0, 0, 0
	end
end

function cVector:add(vec)
	return Vector(self.X + vec.X, self.Y + vec.Y, self.Z + vec.Z)
end

function cVector:sub(vec)
	return Vector(self.X - vec.X, self.Y - vec.Y, self.Z - vec.Z)
end

function cVector:mul(vecOrScalar)
	if type(vecOrScalar) == "table" then
		local vec = vecOrScalar
		return Vector(self.X * vec.X, self.Y * vec.Y, self.Z * vec.Z)
	elseif type(vecOrScalar) == "number" then
		local scalar = vecOrScalar
		return Vector(self.X * scalar, self.Y * scalar, self.Z * scalar)
	else
		error("Invalid type @ Vector.mul")
	end
end

function cVector:div(vecOrScalar)
	if type(vecOrScalar) == "table" then
		local vec = vecOrScalar
		return Vector(self.X / vec.X, self.Y / vec.Y, self.Z / vec.Z)
	elseif type(vecOrScalar) == "number" then
		local scalar = vecOrScalar
		return Vector(self.X / scalar, self.Y / scalar, self.Z / scalar)
	else
		error("Invalid type @ Vector.div")
	end
end

function cVector:invert()
	return Vector(-self.X, -self.Y, -self.Z)
end

function cVector:equalTo(vec)
	return (self.X == vec.X and self.Y == vec.Y and self.Z == vec.Z)
end

function cVector:lt(vec) -- is there an operation like this?
	return (self.X < vec.X and self.Y < vec.Y and self.Z < vec.Z)
end

function cVector:le(vec)
	return (self.X <= vec.X and self.Y <= vec.Y and self.Z <= vec.Z)
end

function cVector:length()
	return math.sqrt(self.X^2 + self.Y^2 + self.Z^2)
end

function cVector:norm()
	return self:div(self:length())
end

function cVector:dotP(vec) -- scalar product
	return (self.X * vec.X + self.Y * vec.Y + self.Z * vec.Z)
end

function cVector:crossP(vec) -- cross product
	return Vector(self.Y * vec.Z - self.Z * vec.Y, self.Z * vec.X - self.X * vec.Z, self.X * vec.Y - self.Y * vec.X)
end

function cVector:isColinear(vec)
	local factor = vec.X / self.X
	return (self.Y * factor == vec.Y and self.Z * factor == vec.Z)
end

function cVector:isOrthogonal(vec)
	return (self:dotP(vec) == 0)
end

function cVector:angle(vec)
	return math.deg(math.acos(self:dotP(vec) / ( self:length() * vec:length() )))
end

function cVector:tostring()
	return ("X = %f, Y = %f; Z = %f"):format(self.X, self.Y, self.Z)
end


-- Operators
function cVector.__add(vec1, vec2)
	return vec1:add(vec2)
end

function cVector.__sub(vec1, vec2)
	return vec1:sub(vec2)
end

function cVector.__mul(vec1, vecOrScalar)
	return vec1:mul(vecOrScalar)
end

function cVector.__div(vec1, vecOrScalar)
	return vec1:div(vecOrScalar)
end

function cVector.__unm(vec)
	return vec:invert()
end

function cVector.__eq(vec1, vec2)
	return vec1:equalTo(vec2)
end

function cVector.__lt(vec1, vec2)
	return vec1:lt(vec2)
end

function cVector.__le(vec1, vec2)
	return vec2:le(vec2)
end

function cVector.__tostring(vec)
	return vec:tostring()
end