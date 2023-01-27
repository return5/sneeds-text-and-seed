
--[[
sneed's text and seed - generate random text based on an input file.
    Copyright (C) <2023>  <return5>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]


local ReadFile <const> = require('ReadFile')

--get the first key which is inside of the tbl[key] table.
--allows us to grab a word which follows the key inside the table.
local function getWordFromTbl(tbl,key)
    for k,_ in pairs(tbl[key]) do
        return k
    end
end

--get a random word4 from the word4 array
local function getWord4(word1,word2,word3,tbl,rand)
    return tbl[word1][word2][word3][rand(#tbl[word1][word2][word3])]
end

--when we don't have a match in the table for word1,word2,and word3 (tbl[word1][word2][word3] == nil)
--we need to grab three new words to keep going with.
local function getNewRandWords(tbl,keys,rand)
    local word1 <const> = keys[rand(#keys)]
    local word2 <const> = getWordFromTbl(tbl,word1)
    local word3 <const> = getWordFromTbl(tbl[word1],word2)
    return word2,word3,getWord4(word1,word2,word3,tbl,rand)
end

--decide when to print a newline character.
--our sophisticated way is to check if the word ends with a . a ? or a !, then if the length of the sentence is > 8 words we print new line.
local function newLineFunc(word3,textTbl,length,match)
    if match(word3,"[.?!]$") and length > 8 then
        textTbl[#textTbl + 1] = "\n"
        return 0
    end
    textTbl[#textTbl + 1] = " "
    return length + 1
end

--when we start generating random text when need to init the first three words.
--here we grab a random word1, then using that grab the next two words.
--we then fill in the first values inside of the text table.
local function initWords(tbl,keys,textTbl,rand)
    local word1,word2,word3 <const> = getNewRandWords(tbl,keys,rand)
    textTbl[1] = word1
    textTbl[2] = " "
    textTbl[3] = word2
    textTbl[4] = " "
    textTbl[5] = word3
    textTbl[6] = " "
    return word1,word2,word3
end

local function generateTextLoopBody(word1,word2,word3,generator,rand,keys,textTbl,length,match)
    local word4
    if not generator[word1] or not generator[word1][word2] or not generator[word1][word2][word3] then
        word2,word3,word4 = getNewRandWords(generator,keys,rand)
    else
        word4 = getWord4(word1,word2,word3,generator,rand)
    end
    word1 = word2
    word2 = word3
    word3 = word4
    textTbl[#textTbl + 1] = word4
    return word2,word3,word4,newLineFunc(word4,textTbl,length,match)
end

--generate our new random text
local function generateText(generator,keys,limit,finish)
    local rand <const> = math.random
    local match <const> = string.match
    local textTbl <const> = {}
    local word1,word2,word3 = initWords(generator,keys,textTbl,rand)
    local length = 0
    for i=1,limit,1 do
        word1,word2,word3,length = generateTextLoopBody(word1,word2,word3,generator,rand,keys,textTbl,length,match)
    end
    if finish then
        length = 1
        while length > 0 do
            word1,word2,word3,length = generateTextLoopBody(word1,word2,word3,generator,rand,keys,textTbl,length,match)
        end
    end
    return table.concat(textTbl)
end

--we scan through the text. we use three words in a row. the first two are the keys, and the third is what we print.
--we accomplish this by using the first word as the key to a table. the values of that table are the second words to appear after that first one.
--we use the second word as keys to a third table.
--we use the third word as a key to an array of fourth words.
--example. in the sentence: i then went home. the table structure will be {i = {then = {went = {home}}}}
local function generateGeneratorTbl(file)
    local toString <const> = tostring
    local tbl <const> = {}
    --we hold an array of all the first words. we use this later to grab a random word to seed our sentence with.
    local keys <const> = {}
    for i=4,#file,1 do
        local word1 <const> = toString(file[i-3])
        local word2 <const> = toString(file[i-2])
        local word3 <const> = toString(file[i-1])
        local word4 <const> = toString(file[i])
        if not tbl[word1] then
            tbl[word1] = {}
            keys[#keys +1] = word1
        end
        if not tbl[word1][word2] then
            tbl[word1][word2] = {}
        end
        if not tbl[word1][word2][word3] then
            tbl[word1][word2][word3] = {}
        end
        tbl[word1][word2][word3][#tbl[word1][word2][word3] + 1] = word4
    end
    return tbl,keys
end

--write random text to a file. if no file is given then use stdout
local function writeFile(text,file)
    if file then
        local f <const> = io.open(file,"a+")
        if f then
            f:write(text)
            f:close()
        else
            io.stderr:write("file '",file,"' could not be opened.\n")
        end
    else
        io.write(text,"\n")
    end
end

local function printUsage()
    io.write("sneed's text and seed [inputFile] [outputLength] [outputFile]\n")
    io.write("generate random text based on input text.\n")
    io.write("\tinputFile - the input text to analyze. should be a simple text file.\n")
    io.write("\toutputLength - number of words to generate based on text. provide a positive integer value.\n")
    io.write("\toutputFile - the file to write generated text to. if none is provided then write to stdout.\n")
end

local function main()
    math.randomseed(os.time())
    if #arg > 1 then
        local file <const> = ReadFile:new(arg[1],"[%w%p-]+",false)
        if #file < 4 then
            io.stderr:write("input text is too short. needs a minimum of four words.\n")
            os.exit(false,true)
        end
        local generatorTbl,keys <const> = generateGeneratorTbl(file)
        local text <const> = generateText(generatorTbl,keys,arg[2],arg[3])
        writeFile(text,arg[4])
    else
        printUsage()
    end
end

main()
