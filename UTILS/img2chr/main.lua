require "tile"

function love.load()

	OVERLAY_SHOWN = true;

	scrollX = 0; scrollY = 0; ZOOM = 4;
	quantisedBitmap = {};
	tiles = {};
	tilemap = {};
end

function love.update(dt)
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		scrollY = scrollY - 4;
	end
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		scrollY = scrollY + 4;
	end
	if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		scrollX = scrollX - 4;
	end
	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		scrollX = scrollX + 4;
	end
end

function love.keypressed(key)
	if key == "space" then
		OVERLAY_SHOWN = not OVERLAY_SHOWN;
	end
	if key == "=" then
		ZOOM = ZOOM + 1;
	end
	if key == "-" then
		ZOOM = math.max(1,ZOOM-1);
	end
end

function optimiseImage()
	-- for each tile, iterates through all the tiles before it and looks for exact matches. 
	-- marks them for consolidation if matching
	for i = 2, #tiles do
		for j = 1, (i - 1) do
			if tiles[i]:isEqual( tiles[j] ) then
				tiles[i].markedForConsolidation = true;
			end
		end
	end
end

function tileImage()
	tiles = {};
	tilemap = {};
	widthInTiles  = math.ceil(imageData:getWidth() / 8);
	heightInTiles = math.ceil(imageData:getHeight() / 8);
	
	-- generates tileset
	for x = 0, widthInTiles - 1 do
		for y = 0, heightInTiles - 1 do
			
			local currtile = Tile:new(); currtile.x = x; currtile.y = y;
			table.insert(tiles, currtile);
			currtile:putData();
			
		end
	end
end

function quantiseImage()
	-- output table init
	quantisedBitmap = {};
	for i = 0, imageData:getWidth() do
		quantisedBitmap[i] = {}
	end
	
	-- FIRST PASS: index all the colors into a table.
	-- each distinct color val it finds will be a key in the table with value "true"
	local colors = {}
	local colorcount = 0;
	
	for x = 0, imageData:getWidth() - 1 do
		for y = 0, imageData:getHeight() - 1 do
			
			local r,g,b,a  = imageData:getPixel(x,y);
			local pixelval = value(r,g,b,a);
			
			if not colors[pixelval] then
				colors[pixelval] = true;
				colorcount = colorcount + 1;
			end
		end
	end
	-- table with all the keys of colors (note: indexes start from one because of sort functionality)
	local colorkeys = {}; local n = 1;
	for k,v in pairs(colors) do colorkeys[n] = k; n = n + 1; end
	table.sort(colorkeys);
	
	-- now all the colors are flattened down to values between 0 and 3 
	for i = 1, colorcount do
		local averagecolor = math.floor(4 * ((i - 1) / colorcount))
		colors[ colorkeys[i] ] = averagecolor;
		print(averagecolor)
	end
	
	-- SECOND PASS: make a new table with the flattened colors
	for x = 0, imageData:getWidth() - 1 do
		for y = 0, imageData:getHeight() - 1 do
		
			local r,g,b,a  = imageData:getPixel(x,y);
			local pixelval = value(r,g,b,a);
			local newcolor = colors[pixelval];
			
			quantisedBitmap[x][y] = newcolor;
		end
	end
end

function love.filedropped(file)
	imageData = love.image.newImageData(file);
	image = love.graphics.newImage(imageData);
	
	quantiseImage();
	tileImage();
	optimiseImage();
end

function love.draw()
	love.graphics.push()
	love.graphics.translate(-scrollX,-scrollY);
	love.graphics.scale(ZOOM)
	
	-- RENDER ORIGINAL IMAGE:
	--if (image) then love.graphics.draw(image,0,0); end
	
	-- RENDER BITMAP:
	-- if quantisedBitmap[0] then
		-- for x = 0, imageData:getWidth() - 1 do
			-- for y = 0, imageData:getHeight() - 1 do
				
				-- local p = quantisedBitmap[x][y];
				-- love.graphics.setColor(p/3,p/3,p/3)
				-- love.graphics.rectangle("fill",x,y,1,1)
			-- end
		-- end
	-- end
	
	-- RENDER TILESET:
	for i = 1, #tiles do
		local t = tiles[i];
		local sx = t.x * 8; local sy = t.y * 8;
		for j = 1, 64 do
			
			local cx = sx + ((j - 1) % 8); local cy = sy + math.floor((j - 1) / 8);
			local p = t.data[j];
			love.graphics.setColor(p/3,p/3,p/3)
			love.graphics.rectangle("fill",cx,cy,1,1)
		end
	end
	
	love.graphics.pop()
	
	if OVERLAY_SHOWN then
		love.graphics.setColor(1,0,0);
		for i = 1, #tiles do
			love.graphics.rectangle("line", tra_x(8 * tiles[i].x), tra_y(8 * tiles[i].y), 8 * ZOOM, 8 * ZOOM);
		end
		love.graphics.setColor(1,0,0,0.33);
		for i = 1, #tiles do
			if tiles[i].markedForConsolidation then
				love.graphics.rectangle("fill", tra_x(8 * tiles[i].x), tra_y(8 * tiles[i].y), 8 * ZOOM, 8 * ZOOM);
			end
		end
	end
end

function value(r,g,b,a)
	return (( r + g + b ) / 3)
end

function tra_x(x)
	return (x * ZOOM) - scrollX;
end
function tra_y(y)
	return (y * ZOOM) - scrollY;
end