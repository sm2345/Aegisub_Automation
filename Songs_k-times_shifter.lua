--[[
README:

This automation for Aegisub allows for easy shifting of song k-times without changing the times themselves. Tested on r8484.

In many cases, we come across this while shifting songs: the times of the lines are perfect, but the k-times are off by say, 1 or 2 frames, forward or backward.

In that case, changing the offsets at the beginning of each line, or the first syllable by itself is a lot of manual work. This is where this automation comes in.

By looking at the audio waveform and maybe some trial-and-error, most of the time, the offset, positive or negative can be determined.

For 23.976 fps anime, it's usually 4 per frame, though sometimes, a half-frame adjustment of value 2 may be needed as well. 

Usage:

Just select the lines that need adjustment after shifting the timings, and enter the offset (positive for "forward" shifting, negative for "backward" shifting) and hit OK.

As of version 0.1, this can only work on lines that are selected. Also, it takes the first {\k} value. Also works for \kf, \ko and \kt tags too.

TODO:
1)Make it work for any selected styles (OP Romaji etc etc)
2)Do more testing

Acknowledgements:

First up, many thanks to lyger for making this awesome automation-writing guide at http://unanimated.github.io/ts/lua/ts-auto_tutorial.htm It acquianted me with the basics and helped a lot.
Also, many thanks to the awesome folks at #Irrational-typesetting-wizardry@irc.rizon.net for their continued advice!

]]
include("karaskel.lua") 

--Script properties
script_name="Songs' k-times shifter"
script_description="Shifts the k-times of lines by a given offset (positive or negative) without changing the line timings themselves"
script_author="sm2345"
script_version="0.1"


function shift_ktimes(sub, sel, act)
	
	--Collect info
	local meta, styles = karaskel.collect_head(sub,false) 
	
dialog_config=
{
    {
        class="dropdown",name="styleselect",
        x=1,y=0,width=1,height=1,
        items={"Selected lines"},
        value = "Selected lines"
		
    },
    {
        class="label",name="label2",
        x=0,y=0,width=1,height=1,
        label="Choose style:"

    },
    {
        class="label",
        x=0,y=1,width=1,height=1,
        label="Enter the amount in centiseconds to shift by (4 = 1 frame for 23.976 fps): "
    },
    {
        class="intedit",name="shift_amt",
        x=1,y=1,width=1,height=1,
        value=0
    }
} 

pressed, results = aegisub.dialog.display(dialog_config)

if pressed=="Cancel" then
    aegisub.cancel()
end
	
	--Keep in mind that si is the index in sel, while li is the line number in sub
	for si,li in ipairs(sel) do
		--Read in the line
		line = sub[li]

		--Do stuff to line here
	--	k_tag = string.match(line.text, '({\\k[fot]?%d+})') --Take out first k-tag, for example: {\k12}
	--	duration = string.match(k_tag, '{\\k[fot]?(%d+)}') --Take 12 from the {\k12}, could've done this in one step I think, but kept it like this for better clarity
	--	duration = duration + count --Add the user-specified offset
		
		duration = tonumber(string.match(line.text, '{.-\\k[oft]?(%--%d+)')) 
		--[[
			Explanation of the pattern:
			
			Suppose we have a line as, "aaa{\\fad(0,500)\\kf11\\k12\\alpha&HAA&}{\\k1222}ta{\\k11}aa{\\kf144}te"
			What we have of interest here is the \kf11, and specifically, the 11, since that's what we want to use for
			shifting the k-times.
			
			The &-- is for the first occurrence of -, for dealing with negative k-times.
			
			So we first match a {, followed by any number of tags. One special thing to note is that we use the "-" operator,
			which matches zero or more times, AS FEW TIMES AS POSSIBLE. So this should only match once: for the first time it finds the match.
			Then we isolate the \k or \kf or \ko or \kt tag, and get the duration out of it.
			
			We change the duration, and substitute it in the main line.
		
		]]
		--The amount we need to shift, 4 = 1 frame.
		
		duration2 = duration + results.shift_amt
		
		--Find the actual number value of the first \k tag, and replace it with the changed one
		--We need to preserve value of all things before and after the duration, and ensure everything is replaced only once
		line.text = string.gsub(line.text, '({.-\\k[oft]?)(%--%d+)', '%1'..duration2, 1) 
		
		--Put the line back in the subtitles
		sub[li] = line
	end
	aegisub.set_undo_point(script_name)
	return sel
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,shift_ktimes)