-- this file could use some significant refactoring or probably something close to a full rewrite -mina

local update = false

local rtTable
local rates
local rateIndex = 1
local scoreIndex = 1
local score
local pn = GAMESTATE:GetEnabledPlayers()[1]
local nestedTab = 1
local nestedTabs = {"Local", "Online"}

local frameX = 10
local frameY = 45
local frameWidth = capWideScale(360,460)
local frameHeight = 350
local fontScale = 0.4
local offsetX = 10
local offsetY = 30
local netScoresPerPage = 8
local netScoresCurrentPage = 1
local nestedTabButtonWidth = 153
local nestedTabButtonHeight = 20
local netPageButtonWidth = 50
local netPageButtonHeight = 50

local selectedrateonly

local judges = {'TapNoteScore_W1','TapNoteScore_W2','TapNoteScore_W3','TapNoteScore_W4','TapNoteScore_W5','TapNoteScore_Miss','HoldNoteScore_Held','HoldNoteScore_LetGo'}

local defaultRateText = ""
if themeConfig:get_data().global.RateSort then
	defaultRateText = "1.0x"
else
	defaultRateText = "All"
end

local ret = Def.ActorFrame{
	BeginCommand=function(self)
		self:queuecommand("Set"):visible(false)
	end,
	OffCommand=function(self)
		self:bouncebegin(0.2):xy(-500,0):diffusealpha(0) -- visible(false)
	end,
	OnCommand=function(self)
		self:bouncebegin(0.2):xy(0,0):diffusealpha(1)
	end,
	SetCommand=function(self)
		self:finishtweening()
		if getTabIndex() == 2 then
			self:queuecommand("On")
			self:visible(true)
			update = true
			self:playcommand("InitScore")
			MESSAGEMAN:Broadcast("ScoreUpdate")
		else 
			self:queuecommand("Off")
			update = false
			MESSAGEMAN:Broadcast("ScoreUpdate")
		end
	end,
	TabChangedMessageCommand=function(self)
		self:queuecommand("Set")
	end,
	CodeMessageCommand=function(self,params)
		if update and nestedTab == 1 then
			if params.Name == "NextRate" then
				rateIndex = ((rateIndex)%(#rates))+1
				scoreIndex = 1
			elseif params.Name == "PrevRate" then
				rateIndex = ((rateIndex-2)%(#rates))+1
				scoreIndex = 1
			elseif params.Name == "NextScore" then
				if rtTable[rates[rateIndex]] ~= nil then
					scoreIndex = ((scoreIndex)%(#rtTable[rates[rateIndex]]))+1
				end
			elseif params.Name == "PrevScore" then
				if rtTable[rates[rateIndex]] ~= nil then
					scoreIndex = ((scoreIndex-2)%(#rtTable[rates[rateIndex]]))+1
				end
			end
			if rtTable[rates[rateIndex]] ~= nil then
				score = rtTable[rates[rateIndex]][scoreIndex]
				setScoreForPlot(score)
				MESSAGEMAN:Broadcast("ScoreUpdate")
			end
		end
	end,
	UpdateChartMessageCommand=function(self)
		self:queuecommand("Set")
	end,
	InitScoreCommand=function(self)
			if GAMESTATE:GetCurrentSong() ~= nil then
				rtTable = getRateTable()
				if rtTable ~= nil then
					rates,rateIndex = getUsedRates(rtTable)
					scoreIndex = 1
					
					-- shouldn't need this check but there seems to be some sort of bug during profile save/load with phantom scores being loaded
					if rtTable[rates[rateIndex]] then
						score = rtTable[rates[rateIndex]][scoreIndex]
						setScoreForPlot(score)
					end
				else
					rtTable = {}
					rates,rateIndex = {defaultRateText},1
					scoreIndex = 1
					score = nil
					setScoreForPlot(score)
				end
			else
				rtTable = {}
				rates,rateIndex = {defaultRateText},1
				scoreIndex = 1
				score = nil
				setScoreForPlot(score)
			end
			MESSAGEMAN:Broadcast("ScoreUpdate")
	end
}

ret[#ret+1] = Def.Quad{InitCommand=function(self)
	self:xy(frameX,frameY):zoomto(frameWidth,frameHeight):halign(0):valign(0):diffuse(color("#333333CC"))
end}


local t = Def.ActorFrame {
	SetCommand=function(self)
		self:visible(nestedTab == 1)
	end,
	NestedTabChangedMessageCommand=function(self)
		self:queuecommand("Set")
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end,
}

t[#t+1] = LoadFont("Common Large")..{
	Name="Grades",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+20):zoom(0.6):halign(0):maxwidth(50/0.6)
	end,
	SetCommand=function(self)
		if score and update then
			self:settext(THEME:GetString("Grade",ToEnumShortString(score:GetWifeGrade())))
			self:diffuse(getGradeColor(score:GetWifeGrade()))
		else
			self:settext("")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

-- Wife display
t[#t+1] = LoadFont("Common Normal")..{
	Name="Score",
	InitCommand=function(self)
		self:xy(frameX+offsetX+55,frameY+offsetY+15):zoom(0.5):halign(0)
	end,
	SetCommand=function(self)
		if score and update then
			if score:GetWifeScore() == 0 then 
				self:settextf("NA (%s)", "Wife")
			else
				self:settextf("%05.2f%% (%s)", notShit.floor(score:GetWifeScore()*10000)/100, "Wife")
			end
		else
			self:settextf("00.00%% (%s)", "Wife")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="Score",
	InitCommand=function(self)
		self:xy(frameX+offsetX+55,frameY+offsetY+33):zoom(0.5):halign(0)
	end,
	SetCommand=function(self)
		if score and update then
			if score:GetWifeScore() == 0 then 
				self:settext("")
			else
				self:settextf("Highest SSR: %5.2f", score:GetSkillsetSSR("Overall"))
			end
		else
			self:settext("")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="ClearType",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+41):zoom(0.5):halign(0)
	end;
	SetCommand=function(self)
		if score and update then
			self:settext(getClearTypeFromScore(pn,score,0))
			self:diffuse(getClearTypeFromScore(pn,score,2))
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="Combo",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+58):zoom(0.4):halign(0)
	end;
	SetCommand=function(self)
		if score and update then
			local maxCombo = getScoreMaxCombo(score)
			self:settextf("Max Combo: %d",maxCombo)
		else
			self:settext("Max Combo: 0")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="MissCount",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+73):zoom(0.4):halign(0)
	end;
	SetCommand=function(self)
		if score and update then
			local missCount = getScoreMissCount(score)
			if missCount ~= nil then
				self:settext("Miss Count: "..missCount)
			else
				self:settext("Miss Count: -")
			end
		else
			self:settext("Miss Count: -")
		end;
	end;
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="Date",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+88):zoom(0.4):halign(0)
	end;
	SetCommand=function(self)
		if score and update then
			self:settext("Date Achieved: "..getScoreDate(score))
		else
			self:settext("Date Achieved: ")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="Mods",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+103):zoom(0.4):halign(0)
	end;
	SetCommand=function(self)
		if score and update then
			self:settext("Mods: " ..score:GetModifiers())
		else
			self:settext("Mods:")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="StepsAndMeter",
	InitCommand=function(self)
		self:xy(frameX+frameWidth-offsetX,frameY+offsetY+10):zoom(0.5):halign(1)
	end,
	SetCommand=function(self)
		local steps = GAMESTATE:GetCurrentSteps(pn)
		if score and update then
			local diff = getDifficulty(steps:GetDifficulty())
			local stype = ToEnumShortString(steps:GetStepsType()):gsub("%_"," ")
			local meter = steps:GetMeter()
			if update then
				self:settext(stype.." "..diff.." "..meter)
				self:diffuse(getDifficultyColor(GetCustomDifficulty(steps:GetStepsType(),steps:GetDifficulty())))
			end
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:xy(frameX+frameWidth-offsetX,frameY+frameHeight-10):zoom(0.4):halign(1)
	end,
	SetCommand=function(self)
		if rates ~= nil and rtTable[rates[rateIndex]] ~= nil and update then
			self:settextf("Rate %s - Showing %d/%d",rates[rateIndex],scoreIndex,#rtTable[rates[rateIndex]])
		else
			self:settext("No Scores Saved")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = LoadFont("Common Normal")..{
	Name="ChordCohesion",
	InitCommand=function(self)
		self:xy(frameX+frameWidth/40,frameY+frameHeight-10):zoom(0.4):halign(0)
	end,
	SetCommand=function(self)
		if score and update then
			if score:GetChordCohesion() == true then
				self:settext("Chord Cohesion: Yes")
			else
				self:settext("Chord Cohesion: No")
			end
		else
			self:settext("Chord Cohesion:")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = Def.Quad{
	Name="ScrollBar",
	InitCommand=function(self)
		self:xy(frameX+frameWidth,frameY+frameHeight):zoomto(4,0):halign(1):valign(1):diffuse(getMainColor('highlight')):diffusealpha(0.5)
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end,
	SetCommand=function(self,params)
		self:finishtweening()
		self:smooth(0.2)
		if rates ~= nil and rtTable[rates[rateIndex]] ~= nil and update then
			self:zoomy(((frameHeight-offsetY)/#rtTable[rates[rateIndex]]))
			self:y(frameY+offsetY+(((frameHeight-offsetY)/#rtTable[rates[rateIndex]])*scoreIndex))
		else
			self:zoomy(frameHeight-offsetY)
			self:y(frameY+frameHeight)
		end
	end
}

local function makeText(index)
	return LoadFont("Common Normal")..{
		InitCommand=function(self)
			self:xy(frameX+frameWidth-offsetX,frameY+offsetY+15+(index*15)):zoom(fontScale):halign(1)
		end,
		SetCommand=function(self)
			local count = 0
			if update then
				if rtTable[rates[index]] ~= nil and update then
					count = #rtTable[rates[index]]
				end
				if index <= #rates then
					self:settextf("%s (%d)",rates[index],count)
					if index == rateIndex then
						self:diffuse(color("#FFFFFF"))
					else
						self:diffuse(getMainColor('positive'))
					end
				else
					self:settext("")
				end
			end
		end,
		ScoreUpdateMessageCommand=function(self)
			self:queuecommand("Set")
		end	
	}
end

for i=1,10 do
	t[#t+1] =makeText(i)
end

local function makeJudge(index,judge)
	local t = Def.ActorFrame{InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+125+((index-1)*18))
	end}

	--labels
	t[#t+1] = LoadFont("Common Normal")..{
		InitCommand=function(self)
			self:zoom(0.5):halign(0)
		end,
		BeginCommand=function(self)
			self:settext(getJudgeStrings(judge))
			self:diffuse(byJudgment(judge))
		end
	};

	t[#t+1] = LoadFont("Common Normal")..{
		InitCommand=function(self)
			self:x(120):zoom(0.5):halign(1)
		end,
		SetCommand=function(self)
			if score and update then
				if judge ~= 'HoldNoteScore_Held' and judge ~= 'HoldNoteScore_LetGo' then
					self:settext(getScoreTapNoteScore(score,judge))
				else
					self:settext(getScoreHoldNoteScore(score,judge))
				end
			else
				self:settext("0")
			end
		end,
		ScoreUpdateMessageCommand=function(self)
			self:queuecommand("Set")
		end,
	};

	t[#t+1] = LoadFont("Common Normal")..{
		InitCommand=function(self)
			self:x(122):zoom(0.3):halign(0)
		end,
		SetCommand=function(self)
			if score ~= nil and update then
				if judge ~= 'HoldNoteScore_Held' and judge ~= 'HoldNoteScore_LetGo' then
					local taps = math.max(1,getMaxNotes(pn))
					local count = getScoreTapNoteScore(score,judge)
					self:settextf("(%03.2f%%)",(count/taps)*100)
				else
					local holds = math.max(1,getMaxHolds(pn))
					local count = getScoreHoldNoteScore(score,judge)

					self:settextf("(%03.2f%%)",(count/holds)*100)
				end
			else
				self:settext("(0.00%)")
			end
		end,
		ScoreUpdateMessageCommand=function(self)
			self:queuecommand("Set")
		end	
	};

	return t
end

for i=1,#judges do
	t[#t+1] =makeJudge(i,judges[i])
end

t[#t+1] = LoadFont("Common Normal")..{
	Name="Score",
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+288):zoom(0.5):halign(0)
	end,
	SetCommand=function(self)
		if score ~= nil and update then
			if score:HasReplayData() then 
				self:settext("Show Replay Data")
			else
				self:settext("No Replay Data")
			end
		else
			self:settext("")
		end
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Set")
	end	
}

t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:xy(frameX+offsetX,frameY+offsetY+288):zoomto(120,30):halign(0):diffusealpha(0)
	end,
	MouseLeftClickMessageCommand=function(self)
		if update and nestedTab == 1 then
			if getTabIndex() == 2 and getScoreForPlot() and getScoreForPlot():HasReplayData() and isOver(self) then
				SCREENMAN:AddNewScreenToTop("ScreenScoreTabOffsetPlot")
			end
		end
	end
}


local function ButtonActive(self)
	return isOver(self) and update
end

ret[#ret+1] = t
local netscoreframeWidth = capWideScale(get43size(460),440)
local netscorespacing = 34
local netscoreframex = capWideScale(get43size(70),60)
local netscoreframey = offsetY+netscorespacing/2+5
function updateNetScores(self)
	if not (netScoresCurrentPage < math.ceil(DLMAN:GetTopChartScoreCount(GAMESTATE:GetCurrentSteps(PLAYER_1):GetChartKey())/netScoresPerPage)) then
		netScoresCurrentPage = 1
	end
	MESSAGEMAN:Broadcast("NetScoreUpdate")
end
local eosongid
local netTab = Def.ActorFrame {
	ChartLeaderboardUpdateMessageCommand = function(self,params)
		eosongid = params.songid
		updateNetScores(self)
	end,
	UpdateChartMessageCommand=function(self)
		updateNetScores(self)
	end,
	VisibilityCommand=function(self)
		self:visible(nestedTab == 2)
	end,
	NestedTabChangedMessageCommand=function(self)
		self:queuecommand("Visibility")
	end,
	ScoreUpdateMessageCommand=function(self)
		self:queuecommand("Visibility")
	end,
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy(netscoreframex, frameY+frameHeight+10-netPageButtonHeight*0.45)
		end,
		--prev
		Def.ActorFrame{
			Def.Quad{
				InitCommand=function(self)
					self:zoomto(netPageButtonWidth, netPageButtonHeight):diffusealpha(0)
				end,
				MouseLeftClickMessageCommand=function(self)
					if ButtonActive(self) and update and nestedTab == 2 then
						if netScoresCurrentPage > 1  then
							netScoresCurrentPage = netScoresCurrentPage - 1
						else
							netScoresCurrentPage = math.ceil(DLMAN:GetTopChartScoreCount(GAMESTATE:GetCurrentSteps(PLAYER_1):GetChartKey())/netScoresPerPage)
						end
						MESSAGEMAN:Broadcast("NetScoreUpdate")
					end
				end
			},
			LoadFont("Common Large") .. {
				InitCommand=function(self)
					self:diffuse(getMainColor('positive')):maxwidth(netPageButtonWidth):maxheight(20):zoom(1)
				end,
				BeginCommand=function(self)
					self:settext("Prev")
				end
			}
		},
		--next
		Def.ActorFrame{
			InitCommand=function(self)
				self:x(netscoreframeWidth/1.25)
			end,
			Def.Quad{
				InitCommand=function(self)
					self:zoomto(netPageButtonWidth, netPageButtonHeight):diffusealpha(0)
				end,
				MouseLeftClickMessageCommand=function(self)
					if ButtonActive(self) and update and nestedTab == 2 then
						if netScoresCurrentPage < math.ceil(DLMAN:GetTopChartScoreCount(GAMESTATE:GetCurrentSteps(PLAYER_1):GetChartKey())/netScoresPerPage) then
							netScoresCurrentPage = netScoresCurrentPage + 1
						else
							netScoresCurrentPage = 1
						end
						MESSAGEMAN:Broadcast("NetScoreUpdate")
					end
				end
			},
			LoadFont("Common Large") .. {
				InitCommand=function(self)
					self:diffuse(getMainColor('positive')):maxwidth(netPageButtonWidth):maxheight(20):zoom(1)
				end,
				BeginCommand=function(self)
					self:settext("Next")
				end
			}
		},
		--currentrateonly toggle ps. HURRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR -mina
		Def.ActorFrame{
			InitCommand=function(self)
				self:x(netscoreframeWidth/2.25):halign(0.5)
			end,
			Def.Quad{
				InitCommand=function(self)
					self:zoomto(netPageButtonWidth*2, netPageButtonHeight):diffusealpha(0)
				end,
				MouseLeftClickMessageCommand=function(self)
					if ButtonActive(self) and update and nestedTab == 2 then
						FILTERMAN:ToggleCurrentRateOnlyForOnlineLeaderBoard()
						whee = SCREENMAN:GetTopScreen():GetMusicWheel()
						whee:Move(1)
						whee:Move(-1)
						whee:Move(0)
					end
				end
			},
			LoadFont("Common Large") .. {
				InitCommand=function(self)
					self:diffuse(getMainColor('positive')):maxwidth(netPageButtonWidth*3):maxheight(20):zoom(1)
				end,
				SetCommand=function(self)
					if FILTERMAN:IsCurrentRateOnlyForOnlineLeaderBoard() == 0 then
						self:settext("Displaying All Rates")
					else
						self:settext("Current Rate Only")
					end
				end,
			}
		}
	}
}

-- online scoreboards
local function netscoreitem(drawindex)
	local tmpScore
	local index = drawindex
	local t = Def.ActorFrame {
		Name="scoreItem"..tostring(i),
		NetScoreUpdateMessageCommand=function(self)
			index = drawindex + (netScoresCurrentPage-1)*netScoresPerPage
			tmpScore = DLMAN:GetTopChartScore(GAMESTATE:GetCurrentSteps(PLAYER_1):GetChartKey(), index)
			self:visible(nestedTab == 2 and tmpScore ~= nil)
			
			if not GAMESTATE:GetCurrentSong() then
				tmpScore = nil
			end
		end,
		NestedTabChangedMessageCommand=function(self)
			self:visible(nestedTab == 2 and tmpScore ~= nil)
		end,

		--The main quad
		Def.Quad{
			InitCommand=function(self)
				self:xy(20,netscoreframey+(drawindex*netscorespacing)):zoomto(netscoreframeWidth,30):halign(0):valign(0):diffuse(color("#444444")):diffusealpha(1)
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:diffuse(tmpScore and tmpScore.replaydata and color("#666666") or color("#444444")):diffusealpha(0.4)
			end,
			MouseLeftClickMessageCommand=function(self)
				if ButtonActive(self) and update and nestedTab == 2 and tmpScore and tmpScore.replaydata then
					setOnlineScoreForPlot(tmpScore)
					SCREENMAN:AddNewScreenToTop("ScreenOnlineScoreTabOffsetPlot")
				end
			end
		},
		
		--rank
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframex-25,netscoreframey+netscorespacing/2+(drawindex*netscorespacing)-2):zoom(0.5):valign(0.5):diffuse(getMainColor('positive'))
			end,
			SetCommand=function(self)
				if tmpScore then
					self:settext(index)
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		-- ssr
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframex-14,netscoreframey+17+(drawindex*netscorespacing)):zoom(0.65):halign(0):maxwidth(50):valign(1)
			end,
			SetCommand=function(self)
				if tmpScore then
					self:settextf("%.2f",tmpScore.Overall)
					self:diffuse(byMSD(tmpScore.Overall))
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		-- rate
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframex+2,netscoreframey+23+(drawindex*netscorespacing)):zoom(0.5):halign(0.5):maxwidth((netscoreframeWidth-15)/0.9)
			end,
			SetCommand=function(self)
				if tmpScore then
					self:settext(string.format("%.2f", tmpScore.rate):gsub("%.?0+$", "").."x")
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		--user + user rating (this is kind of cluttery so maybe it should be a mouseover or hold-to-display type deal?) -mina
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframex+28,netscoreframey+14+(drawindex*netscorespacing)):zoom(0.65):halign(0):valign(1):maxwidth((netscoreframeWidth-15)/0.9)
			end,
			SetCommand=function(self)
				if tmpScore then
						if tmpScore.nocc then
							self:diffuse(getMainColor('positive'))
						else
							self:diffuse(color("#F0EEA6"))
						end
					self:settextf("%s: %.2f",tmpScore.username, tmpScore.playerRating)
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		--judgments
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframex+28,netscoreframey+23+(drawindex*netscorespacing)):zoom(0.45):halign(0):maxwidth((netscoreframeWidth-15)/0.9)
			end,
			SetCommand=function(self)
				if tmpScore then
					if tmpScore.nocc then
						self:diffuse(color("#FFFFFF"))
					else
						self:diffuse(color("#F0EEA6"))
					end
				-- The "I"s are simply used for spacing
					self:settextf("%d I %d I %d I %d I %d I %d  x%d",
						tmpScore.marvelous,
						tmpScore.perfect,
						tmpScore.great,
						tmpScore.good,
						tmpScore.bad,
						tmpScore.miss,
						tmpScore.maxcombo)
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		-- wife %
		LoadFont("Common normal")..{ 
			InitCommand=function(self)
				self:xy(netscoreframeWidth+18,netscoreframey+(drawindex*netscorespacing)+17):zoom(0.65):halign(1):maxwidth(100):valign(1)
			end,
			SetCommand=function(self)
				if tmpScore then
					self:settextf("%05.2f%%", tmpScore.wife*10000/100)
					self:diffuse(byGrade(GetGradeFromPercent(tmpScore.wife)))
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},
		
		--date
		LoadFont("Common normal")..{
			InitCommand=function(self)
				self:xy(netscoreframeWidth+18,netscoreframey+20+(drawindex*netscorespacing)+4):zoom(0.35):halign(1)
			end,
			SetCommand=function(self)
				if tmpScore then
					self:settext(tmpScore.datetime)
				else
					self:settext("")
				end
			end,
			NetScoreUpdateMessageCommand=function(self)
				self:queuecommand("Set")
			end,
			BeginCommand=function(self)
				self:queuecommand("Set")
			end,
		},

		-- completely gratuitous eo player profile link button (this is the only one that works atm)
		Def.Quad{
			InitCommand=function(self)
				self:xy(netscoreframex+28,netscoreframey+18+(drawindex*netscorespacing)):zoomto((netscoreframeWidth-15)/1.75,20):halign(0):diffuse(getMainColor('positive')):valign(1):diffusealpha(0)
			end,
			MouseLeftClickMessageCommand=function(self)
				if isOver(self) and nestedTab == 2 then
					local urlstringyo = "https://etternaonline.com/user/"..tmpScore.username
					GAMESTATE:ApplyGameCommand("urlnoexit,"..urlstringyo)
				end
			end
		},
		
		-- completely gratuitous eo song id link button
		Def.Quad{
			InitCommand=function(self)
				self:xy(netscoreframex-25,netscoreframey+netscorespacing/2+(drawindex*netscorespacing)-2):zoomto(20,20):valign(0.5):diffuse(getMainColor('positive')):diffusealpha(0)
			end,
			MouseLeftClickMessageCommand=function(self)
				if isOver(self) and nestedTab == 2 then
					local urlstringyo = "https://etternaonline.com/song/view/"..eosongid
					GAMESTATE:ApplyGameCommand("urlnoexit,"..urlstringyo)
				end
			end
		},
		
		-- completely gratuitous eo player score link button
		Def.Quad{
			InitCommand=function(self)
				self:xy(netscoreframex+28,netscoreframey+23+(drawindex*netscorespacing)):zoomto((netscoreframeWidth-15)/1.75,14):halign(0):diffusealpha(0)
			end,
			MouseLeftClickMessageCommand=function(self)
				if isOver(self) and nestedTab == 2 then
					local urlstringyo = "https://etternaonline.com/score/view/"..tmpScore.scoreid
					GAMESTATE:ApplyGameCommand("urlnoexit,"..urlstringyo)
				end
			end
		},
		
		-- gratuity g-another
		Def.Quad{
			InitCommand=function(self)
				self:xy(netscoreframex-10,netscoreframey+23+(drawindex*netscorespacing)):zoomto(2,2):halign(0):diffusealpha(0)
			end,
			MouseLeftClickMessageCommand=function(self)
				if isOver(self) and nestedTab == 2 then
					local urlstringyo = "https://etternaonline.com/avatars/"..tmpScore.avatar
					GAMESTATE:ApplyGameCommand("urlnoexit,"..urlstringyo)
				end
			end
		},
		--mods (maybe make this be a mouseover later) -mina
		-- LoadFont("Common normal")..{
			-- InitCommand=function(self)
				-- self:xy(netscoreframex-30,netscoreframey+20+(drawindex*netscorespacing)+4):zoom(0.3):halign(0):maxwidth((netscoreframeWidth-15)/0.35)
			-- end,
			-- SetCommand=function(self)
				-- if tmpScore then
					-- self:settext(tmpScore.modifiers)
				-- else
					-- self:settext("")
				-- end
			-- end,
			-- NetScoreUpdateMessageCommand=function(self)
				-- self:queuecommand("Set")
			-- end,
			-- BeginCommand=function(self)
				-- self:queuecommand("Set")
			-- end,
		-- },
	}
	return t
end
for i=1,netScoresPerPage do
	netTab[#netTab+1] = netscoreitem(i)
end
ret[#ret+1] = netTab
function nestedTabButton(i)
	return 
	Def.ActorFrame{
		InitCommand=function(self)
			self:xy(frameX+offsetX+i*(frameWidth*7.55/8)/#nestedTabs-nestedTabButtonWidth/2, frameY+offsetY/2)
		end,
		Def.Quad{
			InitCommand=function(self)
				self:zoomto(nestedTabButtonWidth,nestedTabButtonHeight):diffusealpha(0.35):diffuse(getMainColor('frames'))
			end,
			SetCommand=function(self)
				if nestedTab == i then
					self:diffusealpha(0.5)
				else
					self:diffusealpha(0.25)
				end
			end,
			MouseLeftClickMessageCommand=function(self)
				if ButtonActive(self) then
					nestedTab = i
					MESSAGEMAN:Broadcast("NestedTabChanged")
				end
			end,
			NestedTabChangedMessageCommand=function(self)
				self:queuecommand("Set")
			end
		},
		LoadFont("Common Large") .. {
			InitCommand=function(self)
				self:diffuse(getMainColor('positive')):maxwidth(nestedTabButtonWidth):maxheight(40):zoom(0.5)
			end,
			BeginCommand=function(self)
				self:settext(nestedTabs[i])
			end
		}
	}
end
for i=1,#nestedTabs do 
	ret[#ret+1] = nestedTabButton(i)
end
return ret