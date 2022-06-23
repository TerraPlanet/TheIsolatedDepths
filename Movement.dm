/*
	Smooth Tile Movement
	Special Thanks to Tyruswoo "Woo" for this library!
*/

atom
	movable
		step_size = 3
		var
			shift_step_size = 3
			shift = FALSE
			move_pattern = "fixed"



			move_route = ""

			move_route_repeat = TRUE
			move_route_skip = FALSE
		proc
			MovePattern()
				switch(move_pattern)
					if("fixed") //Do nothing.
					if("random") Step(pick(NORTH, SOUTH, EAST, WEST))
					if("custom") MoveRoute(move_route)
			TurfCount()
				var/count = 0
				for(var/turf/T in obounds(src))
					count += 1
				return count
			MoveRoute(var/route_text="", var/skip=FALSE, var/repeat=TRUE)
				var/list/route = text2routelist(route_text)
				for(var/i=1, i<=length(route), i++)
					var
						R = route[i]
						next_R = 0
					if(i+1 <= length(route)) next_R = route[i+1]
					if(!Step(R, next_R) && !skip)	//If Step fails and skip is not enabled...
						i--							//...then try this Step again.
					if(repeat && i==length(route))
						i=0
			Step(var/d=0, var/next_d=0)
				var/turf/T = locate(x, y, z)
				switch(d)
					if(NORTH) T = locate(x, y+1, z)
					if(EAST)  T = locate(x+1, y, z)
					if(SOUTH) if(step_y == 0) T = locate(x, y-1, z)
					if(WEST)  if(step_x == 0) T = locate(x-1, y, z)
				sleep(1/world.fps)
				if(T && T.DensityCount(src)==0) step(src, d)
				else return FALSE
				var
					step_attempt_max = world.icon_size / step_size
					step_attempt_count = 0
				while(TurfCount()>1)
					sleep(1/world.fps)
					step_attempt_count += 1
					if(step_attempt_count > step_attempt_max)
						Step(turn(d, 180))
						return FALSE
					switch(d)
						if(NORTH)
							if(step_y <= (world.icon_size - step_size)) step(src, NORTH)
							else if(d == next_d) return step(src, NORTH)
							else step(src, NORTH, world.icon_size - step_y)
						if(EAST)
							if(step_x <= (world.icon_size - step_size)) step(src, EAST)
							else if(d == next_d) return step(src, EAST)
							else step(src, EAST, world.icon_size - step_x)
						if(SOUTH)
							if(step_y >= step_size) step(src, SOUTH)
							else if(d == next_d) return step(src, SOUTH)
							else step(src, SOUTH, step_y)
						if(WEST)
							if(step_x >= step_size) step(src, WEST)
							else if(d == next_d) return step(src, WEST)
							else step(src, WEST, step_x)
				return TRUE

turf
	proc
		DensityCount(var/mob/M) //Return number of dense atoms, or -1 if no atoms found.
			var/count = -1
			for(var/atom/A in bounds(src))
				if(A && (count < 0)) count = 0		//Found the first atom.
				if(A.density && A!=M) count += 1	//Found a dense mob (not the mob trying to move).
			return count

client
	var
		move_key = 0	//Keep track of the most recent direction key press.
	Northeast()
	Northwest()
	Southeast()
	Southwest()
	North()
		var/turf/T = locate(mob.x, mob.y+1, mob.z)
		if(mob.TurfCount()<=1 && !move_key && T && T.DensityCount()==0)
			move_key = NORTH
			SmoothNorth()
	East()
		var/turf/T = locate(mob.x+1, mob.y, mob.z)
		if(mob.TurfCount()<=1 && !move_key && T && T.DensityCount()==0)
			move_key = EAST
			SmoothEast()
	South()
		var/turf/T = locate(mob.x, mob.y-1, mob.z)
		if(mob.TurfCount()<=1 && !move_key && T && T.DensityCount()==0)
			move_key = SOUTH
			SmoothSouth()
	West()
		var/turf/T = locate(mob.x-1, mob.y, mob.z)
		if(mob.TurfCount()<=1 && !move_key && T && T.DensityCount()==0)
			move_key = WEST
			SmoothWest()
	verb
		NorthReleased()
			set hidden = 1
			if(move_key == NORTH) move_key = 0
		EastReleased()
			set hidden = 1
			if(move_key == EAST) move_key = 0
		SouthReleased()
			set hidden = 1
			if(move_key == SOUTH) move_key = 0
		WestReleased()
			set hidden = 1
			if(move_key == WEST) move_key = 0
		RunStart()
			set hidden = 1
			mob.shift = TRUE
		RunStop()
			set hidden = 1
			mob.shift = FALSE
	proc
		SmoothNorth()
			var/turf/T = locate(mob.x, mob.y+1, mob.z)
			while(mob.TurfCount()>1 || (move_key == NORTH && T && T.DensityCount()==0))
				sleep(1/world.fps)
				if(!mob.shift)
					if((move_key == NORTH && T && T.DensityCount()==0) || (mob.step_y <= (world.icon_size - mob.step_size)))
						if(!step(mob, NORTH)) return SmoothSouth()
					else if(!step(mob, NORTH, world.icon_size - mob.step_y)) return SmoothSouth()
				else
					if((move_key == NORTH && T && T.DensityCount()==0) || (mob.step_y <= (world.icon_size - mob.shift_step_size)))
						if(!step(mob, NORTH, mob.shift_step_size)) return SmoothSouth()
					else if(!step(mob, NORTH, world.icon_size - mob.step_y)) return SmoothSouth()
				T = locate(mob.x, mob.y+1, mob.z)
		SmoothEast()
			var/turf/T = locate(mob.x+1, mob.y, mob.z)
			while(mob.TurfCount()>1 || (move_key == EAST && T && T.DensityCount()==0))
				sleep(1/world.fps)
				if(!mob.shift)
					if((move_key == EAST && T && T.DensityCount()==0) || (mob.step_x <= (world.icon_size - mob.step_size)))
						if(!step(mob, EAST)) return SmoothWest()
					else if(!step(mob, EAST, world.icon_size - mob.step_x)) return SmoothWest()
				else
					if((move_key == EAST && T && T.DensityCount()==0) || (mob.step_x <= (world.icon_size - mob.shift_step_size)))
						if(!step(mob, EAST, mob.shift_step_size)) return SmoothWest()
					else if(!step(mob, EAST, world.icon_size - mob.step_x)) return SmoothWest()
				T = locate(mob.x+1, mob.y, mob.z)
		SmoothSouth()
			var/turf/T = locate(mob.x, mob.y-1, mob.z)
			while(mob.TurfCount()>1 || (move_key == SOUTH && T && T.DensityCount()==0))
				sleep(1/world.fps)
				if(!mob.shift)
					if((move_key == SOUTH && T && T.DensityCount()==0) || (mob.step_y >= mob.step_size))
						if(!step(mob, SOUTH)) return SmoothNorth()
					else if(!step(mob, SOUTH, mob.step_y)) return SmoothNorth()
				else
					if((move_key == SOUTH && T && T.DensityCount()==0) || (mob.step_y >= mob.shift_step_size))
						if(!step(mob, SOUTH, mob.shift_step_size)) return SmoothNorth()
					else if(!step(mob, SOUTH, mob.step_y)) return SmoothNorth()
				T = locate(mob.x, mob.y-1, mob.z)
		SmoothWest()
			var/turf/T = locate(mob.x-1, mob.y, mob.z)
			while(mob.TurfCount()>1 || (move_key == WEST && T && T.DensityCount()==0))
				sleep(1/world.fps)
				if(!mob.shift)
					if((move_key == WEST && T && T.DensityCount()==0) || (mob.step_x >= mob.step_size))
						if(!step(mob, WEST)) return SmoothEast()
					else if(!step(mob, WEST, mob.step_x)) return SmoothEast()
				else
					if((move_key == WEST && T && T.DensityCount()==0) || (mob.step_x >= mob.shift_step_size))
						if(!step(mob, WEST, mob.shift_step_size)) return SmoothEast()
					else if(!step(mob, WEST, mob.step_x)) return SmoothEast()
				T = locate(mob.x-1, mob.y, mob.z)

//Global proc
proc
	text2routelist(var/route_text = "")	//Text containing "N", "E", "S", or "W" is converted to a list containing NORTH, EAST, SOUTH or WEST.
		var/list/route_list = list()
		for(var/i=1, i<=length(route_text), i++)
			var/L = copytext(route_text, i, i+1)
			switch(L)
				if("N") route_list.Add(NORTH)
				if("E") route_list.Add(EAST)
				if("S") route_list.Add(SOUTH)
				if("W") route_list.Add(WEST)
		return route_list