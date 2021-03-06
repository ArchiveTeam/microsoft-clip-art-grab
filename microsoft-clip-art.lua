dofile("urlcode.lua")
dofile("table_show.lua")
JSON = (loadfile "JSON.lua")()

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local yes = false
local yes1 = false
local yes2 = false
local yes3 = false

local downloaded = {}
local addedtolist = {}

--exclude all the following urls:

load_json_file = function(file)
  if file then
    local f = io.open(file)
    local data = f:read("*all")
    f:close()
    return JSON:decode(data)
  else
    return nil
  end
end

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  local html = nil
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if item_type == "clip-art" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if string.match(url, item_value) then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  end
  
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(url)
    if downloaded[url] ~= true and addedtolist[url] ~= true then
      table.insert(urls, { url=url })
      addedtolist[url] = true
    end
  end

  if item_type == "clip-art" then
    if (string.match(url, "http[s]?://[^/]+/[^/]+/images/MP[0-9]+%.aspx") and last_http_statcode ~= 200 and yes1 == false and yes == false) then
      local mcurl = "http://office.microsoft.com/en-us/images/MC"..item_value..".aspx"
      yes1 = true
      check(mcurl)
    elseif (string.match(url, "http[s]?://[^/]+/[^/]+/images/MC[0-9]+%.aspx") and last_http_statcode ~= 200 and yes2 == false and yes == false) then
      local mmurl = "http://office.microsoft.com/en-us/images/MM"..item_value..".aspx"
      yes2 = true
      check(mmurl)
    elseif (string.match(url, "http[s]?://[^/]+/[^/]+/images/MM[0-9]+%.aspx") and last_http_statcode ~= 200 and yes3 == false and yes == false) then
      local msurl = "http://office.microsoft.com/en-us/images/MS"..item_value..".aspx"
      yes3 = true
      check(msurl)
    elseif yes1 == true or yes2 == true or yes3 == true or yes == true or (string.match(url, "http[s]?://[^/]+/[^/]+/images/MP[0-9]+%.aspx") and last_http_statcode == 200 and (yes1 and yes2 and yes3 and yes) == false) then
      yes = true
      local Ms = {"MH", "MB", "MR", "MT"}
      --check all languages
      if (string.match(url, "http[s]?://[^/]+/en%-us/[^/]+/") or string.match(url, "http[s]?://[^/]+/en%-US/[^/]+/")) and last_http_statcode == 200 then
        local languages = {"es-ar", "pt-br", "en-ca", "fr-ca", "es-hn", "es-mx", "en-us", "ms-my", "en-au", "en-in", "id-id", "en-nz", "fil-ph", "en-sg", "uz-latn-uz", "vi-vn", "kk-kz", "ru-ru", "hi-in", "th-th", "ko-kr", "zh-cn", "zh-tw", "ja-jp", "zh-hk", "az-latn-az", "nl-be", "fr-be", "cs-cz", "da-dk", "de-de", "et-ee", "es-es", "ca-es", "fr-fr", "hr-hr", "en-ie", "it-it", "lv-lv", "lt-lt", "hu-hu", "nl-nl", "nb-no", "de-at", "pl-pl", "pt-pt", "sr-latn-cs", "ro-ro", "de-ch", "sq-al", "sl-si", "sk-sk", "fr-ch", "fi-fi", "sv-se", "tr-tr", "en-gb", "el-gr", "be-by", "bg-bg", "mk-mk", "ru-ru", "uk-ua", "en-za", "tr-tr", "he-il", "ar-sa", "en-001", "fr-001"}
        local urlstart = string.match(url, "(http[s]?://[^/]+/)")
        local urlend = string.match(url, "http[s]?://[^/]+/[^/]+(/images/.+)")
        for k, v in pairs(languages) do
          local newurl = urlstart..v..urlend
          check(newurl)
        end
      end
      
      if string.match(url, "M[PCM][0-9]+%.jpg%?Download=1") and last_http_statcode == 404 then
        for k, v in pairs(Ms) do
          local newurl = string.gsub(url, item_value..".jpg", item_value..".png")
          check(newurl)
          local prenewurl = string.match(url, "(http[s]?://[^%?]+)%?Download=1")
          local newurl2 = string.gsub(prenewurl, item_value..".jpg", item_value..".png")
          check(newurl2)
        end
      end
      
      for newurl in string.gmatch(url, "(http[s]?://[^/]+/[^/]+/images/M[PCMS][0-9]+)%.aspx") do
        check(newurl)
      end
      
      if string.match(url, "http[s]?://[^/]+/[^/]+/images/[^%.]+%.aspx[^%?]*") and last_http_statcode == 200 then
        html = read_file(file)
        local ext = string.match(html, '"imgPreview"[^"]+"imgPreview"[^"]+"[^"]*"[^"]+"[^"]*"[^"]+"//[^/]+/[^/]+/[^/]+/[^%.]+(%.[^"]+)"')
        local urlstart = string.match(url, "(http[s]?://[^/]+/[^/]+/images/[^%.]+)%.aspx[^%?]*")
        local newurl = urlstart..ext.."?Download=1"
        check(newurl)
        local newurl2 = urlstart..ext
        check(newurl2)
        for k, v in pairs(Ms) do
          local newurl1 = urlstart..ext
          local newurl3 = string.gsub(newurl1, "M[PCM]"..item_value, v..item_value)
          check(newurl3)
        end
      end
      
      if string.match(url, "http[s]?://[^/]+/[^/]+/images/.+") and last_http_statcode == 200 then
        local newurl1 = string.match(url, "(http[s]?://[^/]+/)[^/]+/images/.+")
        local newurl2 = string.match(url, "http[s]?://[^/]+/[^/]+/(images/.+)")
        local newurl = newurl1..newurl2
        check(newurl)
      end
      
      if string.match(url, "/images/MC[0-9]+%.") and last_http_statcode == 200 then
        local newmcurl = "http://officeimg.vo.msecnd.net/en-us/images/MC"..item_value..".wmf"
        check(newmcurl)
        local newmcurl1 = "http://officeimg.vo.msecnd.net/en-us/images/MC"..item_value..".wmf?Download=1"
        check(newmcurl1)
      elseif string.match(url, "/images/MS[0-9]+%.") and last_http_statcode == 200 then
        local newmsurl = "http://officeimg.vo.msecnd.net/en-us/images/MS"..item_value..".wav"
        check(newmsurl)
        local newmsurl1 = "http://officeimg.vo.msecnd.net/en-us/images/MS"..item_value..".wav?Download=1"
        check(newmsurl1)
      end
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  last_http_statcode = status_code
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) or status_code == 403 then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 1")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
