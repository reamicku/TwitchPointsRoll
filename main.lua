__LAST_MODIFICATION_DATE = "13.07.2019"

parser = {}
parser.lastoutput = nil
parser.lastcommandnoargs = ""
parser.lastcommandwithargs = ""
parser.commandhistory = {}

function parser.setlastoutput(n) parser.lastoutput = n end

function parser.execute(istring,nohistorysaving)
	if istring == "" or istring == " " then
		parser.setlastoutput(3)
		return parser.lastoutput
	end
	local ilen = #istring
	local paramcount = 0
	local readparam = false
	local parambegin = 0
	local paramend = 0
	local params = {

		}
	local istart = 2
	if commands.prefix == "" then
		istart = 1
		--end
	elseif string.sub(istring,1,1) ~= commands.prefix then
		parser.setlastoutput(1)
		return parser.lastoutput
	end

	for i=istart,ilen do
		if string.sub(istring,i,i) ~= " " then
			if not readparam then
				readparam = true
				parambegin = i
				paramcount = paramcount + 1
			end
		else
			readparam = false
			paramend = i-1
			table.insert(params,string.sub(istring,parambegin,paramend))
		end
		if i==ilen then
			readparam = false
			paramend = i
			table.insert(params,string.sub(istring,parambegin,paramend))
		end
	end

    parser.lastcommandnoargs = params[1]
    parser.lastcommandwithargs = istring

	--for i,v in ipairs(params) do print("'"..v.."'") end

	local args = {}
	local cmds = commands.commands
	local cmdid = nil
	for i,v in ipairs(cmds) do
		--print(string.format("Checking if %s == %s --> %s",params[1],cmds[i].cmd,tostring(params[1] == cmds[i].cmd)))
		if params[1] == cmds[i].cmd then
			for j=1,#cmds[i].arguments do
				local p = params[j+1]
				if cmds[i].arguments[j].type == "number" then
					if tonumber(p) == nil then
						--print("!ERR: Argument #"..j.." not a number.")
						--parser.setlastoutput(4)
						--return parser.lastoutput
                        p = nil
                    else
                        p = tonumber(p)
					end
				end
				table.insert(args,p)
			end
			cmdid = i
			break
		end
	end
	if cmdid == nil then
		parser.setlastoutput(2)
		return parser.lastoutput 
	end

    if not nohistorysaving then
        local cmdstr = commands.prefix..cmds[cmdid].cmd
        if #args>0 then
            for i=1,#cmds[cmdid].arguments do
                cmdstr = cmdstr.." "..args[i]
            end
        end
        table.insert(parser.commandhistory,cmdstr)
    end

	cmds[cmdid].f(table.unpack(args))
    
    parser.setlastoutput(0)
	return parser.lastoutput
end

commands = {
	prefix = "!",
	commands = {
        {
			cmd = "help",
			help_cmd = "help [page]",
			help_desc = "Lists all commands with their corresponding descriptions.",
			arguments = {{name="page",type="number"}},
			f = function(a) helplist(a,false) end,
		},
        {
			cmd = "helpc",
			help_cmd = "helpc <command>",
			help_desc = "Displays help for <command> command.",
			arguments = {{name="command",type="string"}},
			f = function(a)
                if a==nil then a = "" end
                local spc_s = "  "
                local spc_inc = "  "
                for i,v in ipairs(commands.commands) do
                    if v.cmd == a then
                        --print(string.format("Showing help for command '%s':",a))
                        --print(v.help_desc)
                        local strcmd = spc_s..spc_inc..commands.prefix..v.help_cmd
                        local strdesc = spc_s..spc_inc..v.help_desc
                        strdesc = string.gsub(strdesc,"\n","\n"..spc_s..spc_inc)
                        print(spc_s.."Command: \n"..strcmd)
                        print(spc_s.."Description: \n"..strdesc)
                        return 0
                    end
                end
                print(string.format("'%s' is not a command.",a))
                return 1
            end,
		},
		{
			cmd = "points",
			help_cmd = "points",
			help_desc = "Shows your current point balance.",
			arguments = {},
			f = function(a) print(string.format("You have %d points.",points)) end,
		},
		{
			cmd = "roll",
			help_cmd = "roll <points>",
			help_desc = "Rolls for <points> amount of points.",
			arguments = {{name="points",type = "number"}},
			f = function(a) roulette(a,false) end,
		},
		{
			cmd = "repeatroll",
			help_cmd = "repeatroll <points> [n]",
			help_desc = "Rolls for <points> amount of points [n] times.",
			arguments = {
                {name="points",type="number"},
                {name="n",type="number"},
            },
			f = function(a,b)
                local a = a or 0
                local b = math.max(1,math.floor(b or 1))
                local i = 0
                while (i < b) do
                    roulette(a,true)
                    i = i + 1
                end
                print("Performed "..i.." of "..b.." rolls.")
            end,
		},
        {
			cmd = "randomroll",
			help_cmd = "randomroll <points> [n]",
			help_desc = "Rolls up to <points> points [n] times.",
			arguments = {
                {name="points",type="number"},
                {name="n",type="number"}
            },
			f = function(a,b)
                local a = a or 0
                local b = math.max(1,math.floor(b or 1))
                local val = nil
                local i = 0
                while (i < b) do
                    val = roulette(math.ceil(a*math.random()),true)
                    if val > 0 then break end
                    i = i + 1
                end
                print("Performed "..i.." of "..b.." random rolls.")
            end,
		},
        {
			cmd = "randomroll2",
			help_cmd = "randomroll2 <percent> [n]",
			help_desc = "Rolls up to <percent> percent of your points [n] times.",
			arguments = {
                {name="percent",type="number"},
                {name="n",type="number"}
            },
			f = function(a,b)
                local a = math.max(0,math.min(100,a or 0))
                local b = math.max(1,math.floor(b or 1))
                local val = nil
                local i = 0
                while (i < b) do
                    val = roulette(math.ceil((0.01*a)*points*math.random()),true)
                    if val > 0 then break end
                    i = i + 1
                end
                print("Performed "..i.." of "..b.." random rolls.")
            end,
		},
        {
			cmd = "randomroll2alg2",
			help_cmd = "randomroll2alg2 <percent> [n] [exp]",
			help_desc = "Rolls up to <percent> percent of your points [n] times.\nUses diffrent formula for deciding roll value.\n[exp] determines algorithm's exponent. Default is 10.",
			arguments = {
                {name="percent",type="number"},
                {name="n",type="number"},
                {name="exp",type="number"},
            },
			f = function(a,b,c)
                local a = math.max(0,math.min(100,a or 0))
                local b = math.max(1,math.floor(b or 1))
                local c = math.floor(math.max(1,math.min(50,c or 10)))
                local val = nil
                local i = 0

                local function sigmoid(x,p)
                    local p = p or 1
                    return 1/(1+math.exp(-p*(x-0.5)))
                end

                while (i < b) do
                    val = roulette(math.ceil((0.01*a)*points*sigmoid(math.random(),c)),true)
                    if val > 0 then break end
                    i = i + 1
                end
                print("Performed "..i.." of "..b.." random rolls.")
            end,
		},
        {
            cmd = "history",
            help_cmd = "history [page]",
            help_desc = "Shows your history of roulettes.",
            arguments = {{name="page",type = "number"}},
            f = function(a) historylist(a) end,
        },
        {
            cmd = "stats",
            help_cmd = "stats",
            help_desc = "Shows your statistics. (WiP)",
            arguments = {},
            f = function()
                showStats()
            end,
        },
        
		{
			cmd = "reset",
			help_cmd = "reset",
			help_desc = "Resets your points to the default value and all your history of rolls.",
			arguments = {},
			f = function() reset() end,
		},
        {
			cmd = "setstartingpoints",
			help_cmd = "setstartingpoints <points>",
			help_desc = "Sets starting points to <points> and performs the reset command.",
			arguments = {{name="points",type="number"}},
			f = function(a)
                local a = math.max(1,a or 1)
                setStartingPoints(a)
                print("Starting points has been set to "..startpoints..".")
                reset()
            end,
		},
		{
			cmd = "clear",
			help_cmd = "clear",
			help_desc = "Clears the console.",
			arguments = {},
			f = function() os.execute("clear") inittext() end,
		},
        {
            cmd = "commandhistory",
			help_cmd = "commandhistory [page]",
			help_desc = "Shows history of successfully issued commands.",
			arguments = {{name="page",type="number"}},
			f = function(a) commandhistorylist(a) end,
        },
        {
            cmd = "setcommandprefix",
            help_cmd = "setcommandprefix [char]",
            help_desc = "Sets command prefix to the [char] character.\nIf no argument specified, then prefix is removed.\n\nValid prefixes:\n! @ # $ % ^ & * / - . = + | ~",
            arguments = {{name="char",type="string"}},
            f = function(a)
                local x = setCommandPrefix(a)
                if x == 0 then
                    print("Prefix has been sucessfully set to '"..a.."'.")
                elseif x == 1 then
                    print("Prefix has been successfully removed.")
                elseif x == 2 then
                    print("Prefix cannot be longer than 1 character!")
                elseif x == 3 then
                    print("Prefix cannot be set to '"..a.."'.\nValid prefixes: ! @ # $ % ^ & * / - . = + | ~")
                end
            end,
        },
        {
			cmd = "exit",
			help_cmd = "exit",
			help_desc = "Exits the program.",
			arguments = {},
			f = function()
				print("Paraser has been aborted.")
				exit = true
			end,
		},
	}
}

function setCommandPrefix(c)
    if c == nil then commands.prefix = "" return 1 end
    local strvalidchars = "!@#$%^&*/-.=+|~"
    if string.len(c) == 1 then
        for i=1,string.len(strvalidchars) do
            if c == string.sub(strvalidchars,i,i) then
                commands.prefix = c
                return 0
            end
        end
        return 3
    else
        return 2
    end
end

function helplist(n,showdesc)
    local elems_per_page = 20
    local entrynum = #commands.commands
    local maxpage = math.ceil(entrynum/elems_per_page)
    local n = math.floor(math.max(1,math.min(n or 1,maxpage)))
    local strtop = "List of commands (Page %d of %d): "
	local strcomm = "  "..commands.prefix.."%s"
	local strdesc = "    %s"
    local strbot = "Showing entries %d-%d of %d."
    local entrystart = 1+elems_per_page*(n-1)
    local entryend = math.min(elems_per_page*(n),entrynum)
    
	print(string.format(strtop,n,maxpage))
	for i=entrystart,entryend do
        if i > entrynum then break end
		print(string.format(strcomm,commands.commands[i].help_cmd))
        if showdesc then
		    print(string.format(strdesc,commands.commands[i].help_desc))
        end
	end
    print(string.format(strbot,entrystart,entryend,entrynum))
end

function historylist(n)
    local elems_per_page = 100
    local entrynum = #history
    local maxpage = math.ceil(entrynum/elems_per_page)
    local n = math.floor(math.min(n or 1,maxpage))
    local strnone = "There is no history of rolls."
    local strtop = "Showing history of rolls (Page %d of %d)"
    local strentry = "   % 5i     % 8d      %s"
    local strlegend = "    Roll       Points      Change"
    local strbot = "Showing entries %d-%d of %d."
    local entrystart = 1+elems_per_page*(n-1)
    local entryend = math.min(elems_per_page*(n),entrynum)

    if entrynum == 0 then print(strnone) return 1 end
    print(string.format(strtop,n,maxpage))
    print(strlegend)
    if n == 1 then print(string.format(strentry,0,historystart,"---").."\n") end
    for i=entrystart, entryend do
        if i > entrynum then break end
        local changenum = -(startpoints - history[i])
        if i > 1 then
            changenum = -(history[i-1] - history[i])
        end
        if changenum > 0 then changenum = "+"..changenum
        else changenum = ""..changenum end
        print(string.format(strentry,i,history[i],changenum))
        if i%10==0 then print() end
    end
    if entryend%10>0 then print() end
    print(string.format(strbot,entrystart,entryend,entrynum))
end

function commandhistorylist(n)
    local elems_per_page = 20
    local entrynum = #parser.commandhistory
    local maxpage = math.ceil(entrynum/elems_per_page)
    local n = math.floor(math.min(n or 1,maxpage))
    local strnone = "There is no history of commands."
    local strtop = "Showing history of commands (Page %d of %d)"
    local strentry = "  %3i  %s"
    local strlegend = "Command"
    local strbot = "Showing entries %d-%d of %d."
    local entrystart = 1+elems_per_page*(n-1)
    local entryend = math.min(elems_per_page*(n),entrynum)

    if entrynum == 0 then print(strnone) return 1 end
    print(string.format(strtop,n,maxpage))
    --print(strlegend)
    for i=entrystart, entryend do
        if i > entrynum then break end
        print(string.format(strentry,i,parser.commandhistory[i]))
        if i%10==0 then print() end
    end
    if entryend%10>0 then print() end
    print(string.format(strbot,entrystart,entryend,entrynum))
end

function addHistoryEntry(x)
    table.insert(history,x)
end

function clearHistoryEntries() history = {} end

function reset(hidden)
    points = startpoints
    historystart = startpoints
    clearHistoryEntries()
    resetStats()
    stats.startpoints = startpoints
    stats.mostpoints = startpoints
    stats.leastpoints = startpoints
    if not hidden then print("Points have been reset.") end
end

function initRand()
	math.randomseed(os.time())
	for i=1,3 do math.random() end
end

function addPoints(n) points = points + n return 0 end
function remPoints(n)
	if points - n < 0 then
		return 1
	else
		points = points - n
		return 0
	end
end

function setStartingPoints(x,start)
    startpoints = x
    if start then points = startpoints end
end

function roll(chanceOffset)
    return math.random()>(0.5-(chanceOffset or 0))
end

function roulette(a,is_hidden)
    local a = a or 0
    a = math.floor(a)
	local strwin  = "You've won %d points and now you have %d of them!"
	local strlost = "You've lost %d points and now you have %d of them!"
	local strerr = "You can't roll for %d points, because you have only %d points."
	if a == 0 then
		if not is_hidden then print("You cannot roll for 0 points.\nIt makes no sense, just think about it.") end
		return 1
	end
	if a < 0 then
		if not is_hidden then print("You cannot roll for negative points.\nIt makes no sense, just think about it.") end
		return 2
	end
	if a > points then
		if not is_hidden then print(string.format(strerr,a,points)) end
		return 3
	end

    local change = a
	if roll() then
		addPoints(a)
        stats.rollspointsgained = stats.rollspointsgained + 1
        stats.currentwinstreak = stats.currentwinstreak + 1
        stats.currentlosestreak = 0
        if stats.currentwinstreak > stats.longestwinstreak then stats.longestwinstreak = stats.currentwinstreak end
		if not is_hidden then print(string.format(strwin,a,points)) end
	else
		remPoints(a)
        stats.rollspointslost = stats.rollspointslost + 1
        stats.currentlosestreak = stats.currentlosestreak + 1
        stats.currentwinstreak = 0
        if stats.currentlosestreak > stats.longestlosestreak then stats.longestlosestreak = stats.currentlosestreak end
		if not is_hidden then print(string.format(strlost,a,points)) end
        change = -change
	end
    addHistoryEntry(points)
    stats.rollsperformed = stats.rollsperformed + 1

    if points > stats.mostpoints then stats.mostpoints = points
    elseif points < stats.leastpoints then stats.leastpoints = points end
    
    if stats.rollspointsgained > 1 then
        if change > stats.mostgained then stats.mostgained = change end
        if change > 0 and change < stats.leastgained then stats.leastgained = change end
    elseif change > 0 then
        stats.mostgained = change
        stats.leastgained = change
    end

    if stats.rollspointslost > 1 then
        if change < -stats.mostlost then stats.mostlost = -change end
        if change < 0 and change > -stats.leastlost then stats.leastlost = -change end
    elseif change < 0 then
        stats.mostlost = -change
        stats.leastlost = -change
    end
    return 0
end

function inittext()
	print("Twitch point rolling simulator. Have fun <3")
	print("Made by reamicku; Last update: "..__LAST_MODIFICATION_DATE)
	print("Type "..commands.prefix.."help for a list of commands.")
end

function showStats()
    local s = "  "
    local strwinratio = string.format("%2.2f%%",100*(stats.rollspointsgained/stats.rollsperformed))
    if stats.rollsperformed == 0 then strwinratio = "Perform at least 1 roll to calculate win ratio." end
    print("Statistics: ")
    print(s.."Current points ....... "..points)
    print(s.."Starting points ...... "..stats.startpoints)
    print()
    print(s.."Rolls performed ...... "..stats.rollsperformed)
    print(s.."Rolls with gain ...... "..stats.rollspointsgained)
    print(s.."Rolls with loss ...... "..stats.rollspointslost)
    print(s.."Win ratio % .......... "..strwinratio)
    print()
    print(s.."Longest win streak.... "..stats.longestwinstreak)
    print(s.."Longest lose streak .. "..stats.longestlosestreak)
    print()
    print(s.."Most points .......... "..stats.mostpoints)
    print(s.."Least points ......... "..stats.leastpoints)
    print()
    print(s.."Most points gained ... "..stats.mostgained)
    print(s.."Least points gained .. "..stats.leastgained)
    print()
    print(s.."Most points lost ..... "..stats.mostlost)
    print(s.."Least points lost .... "..stats.leastlost)
end

function resetStats()
    stats = {}

    stats.currentwinstreak = 0
    stats.currentlosestreak = 0


    stats.startpoints = historystart

    stats.mostpoints = 0
    stats.leastpoints = 0
    
    stats.mostgained = 0
    stats.leastgained = 0

    stats.longestwinstreak = 0
    stats.longestlosestreak = 0

    stats.mostlost = 0
    stats.leastlost = 0

    stats.rollsperformed = 0
    stats.rollspointsgained = 0
    stats.rollspointslost = 0
end

function main()
    history = {}
    historystart = 0

    setCommandPrefix()
    setStartingPoints(100,true)
    reset(true)

    initRand()
    iter = 1
    exit = false
    while not exit do
	    if iter == 1 then
		    parser.execute(commands.prefix.."clear",true)
	    end

	    io.write("\n> ")
	    input = io.read()

	    parser.execute(input)
        if parser.lastoutput == 2 then print("No such command as '"..parser.lastcommandnoargs.."'.") end
	    iter = iter + 1
    end
    return iter
end

main()
