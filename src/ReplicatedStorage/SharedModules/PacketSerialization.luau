local module = {}

function module.WriteNPCIDPacket(ID: number) -- NPC IDs
	local packet = buffer.create(1)
	buffer.writeu8(packet, 0, ID - 1)
	return packet
end

function module.ReadNPCIDPacket(packet: buffer)
	return buffer.readu8(packet, 0) + 1
end

function module.WriteNPCMovementPacket(pos: Vector3, ID: number) -- NPC movetoposition updates
	local packet = buffer.create(7)
	buffer.writeu8(packet, 0, ID - 1)

	buffer.writei16(packet, 1, math.round(pos.X * 10))
	buffer.writei16(packet, 3, math.round(pos.Y * 10))
	buffer.writei16(packet, 5, math.round(pos.Z * 10))

	return packet
end

function module.ReadNPCMovementPacket(packet: buffer)
	local ID = buffer.readu8(packet, 0) + 1

	local pos =
		Vector3.new(buffer.readi16(packet, 1) / 10, buffer.readi16(packet, 3) / 10, buffer.readi16(packet, 5) / 10)

	return ID, pos
end

function module.WriteNPCActionPacket(ID: number, index: number) -- NPC actions
	local packet = buffer.create(2)
	buffer.writeu8(packet, 0, ID - 1)
	buffer.writeu8(packet, 1, index - 1)
	return packet
end

function module.ReadNPCActionPacket(packet: buffer)
	local ID, index = buffer.readu8(packet, 0) + 1, buffer.readu8(packet, 1) + 1
	return ID, index
end

function module.WriteHitPacket(ID: number, numindex: number, damage: number)
	local packet = buffer.create(10)
	buffer.writeu8(packet, 0, ID - 1)
	buffer.writeu8(packet, 1, numindex - 1)
	buffer.writef64(packet, 2, damage)
	return packet
end

function module.ReadHitPacket(packet: buffer)
	local ID = buffer.readu8(packet, 0) + 1
	local index = buffer.readu8(packet, 1) + 1
	local damage = buffer.readf64(packet, 2)

	return ID, index, damage
end

function module.WriteKnockbackPacket(ID: number, dir: Vector3, power: number)
	local packet = buffer.create(9)
	buffer.writeu8(packet, 0, ID - 1)

	buffer.writei16(packet, 1, math.round(dir.X * 10 ^ 4))
	buffer.writei16(packet, 3, math.round(dir.Y * 10 ^ 4))
	buffer.writei16(packet, 5, math.round(dir.Z * 10 ^ 4))

	buffer.writei16(packet, 7, power)

	return packet
end

function module.ReadKnockbackPacket(packet: buffer)
	local ID = buffer.readu8(packet, 0) + 1

	local dir = Vector3.new(
		buffer.readi16(packet, 1) / 10 ^ 4,
		buffer.readi16(packet, 3) / 10 ^ 4,
		buffer.readi16(packet, 5) / 10 ^ 4
	)

	local power = buffer.readi16(packet, 7)

	return ID, dir, power
end

return module
