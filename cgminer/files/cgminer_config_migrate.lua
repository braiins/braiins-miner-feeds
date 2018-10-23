#!/usr/bin/env lua

require 'luci.jsonc'
require 'nixio.fs'

local CGMINER_CONFIG = '/etc/cgminer.conf'

local function migrate_am1(cfg)
	local ver = tonumber(cfg['config-format-revision'])
	if not ver then
		for i = 1, 6 do
			cfg[('A1Pll%d'):format(i)] = nil
		end
		cfg.A1Vol = nil
		cfg['enabled-chains'] = nil
		cfg['bitmain-voltage'] = nil
		-- enable multi-version if upgrading
		cfg['multi-version'] = '4'
	elseif ver == 1 then
		-- latest
		return false
	end
	-- update config format revision
	cfg['config-format-revision'] = '1'
	return true
end

local function migrate_dm1(cfg)
	return false
end

-- migration function takes "json" argument
-- returns true if config was migrated, false if it is the latest revision
migrate_fns = {
	['am1-s9'] = migrate_am1,
}

function main(arg)
	local path = arg[1]
	local platform = arg[2]
	if not path or not platform then
		io.stderr:write('usage: cgminer_config_migrate <config_file> <platform>\n')
		os.exit(1)
	end
	local migrate = migrate_fns[platform]
	if not migrate then
		return
	end
	local str = nixio.fs.readfile(path)
	if not str then error('file not found') end
	cfg = luci.jsonc.parse(str)
	if not cfg then error('json parser failed') end
	
	if migrate(cfg) then
		print('config '..path..' was migrated')
		nixio.fs.writefile(path, luci.jsonc.stringify(cfg))
	end
end

main(arg)
