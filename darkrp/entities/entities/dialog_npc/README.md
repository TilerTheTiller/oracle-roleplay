# Dialog NPC System - DarkRP

A complete dialog NPC system that allows you to create interactive NPCs with branching conversations, actions, and custom responses.

## Features

- ✅ **Multiple NPCs** - Create unlimited NPCs with different dialogs
- ✅ **Branching Conversations** - Chain dialogs together with `nextDialog`
- ✅ **Server Actions** - Execute code when players select options
- ✅ **DarkRP Integration** - Uses DarkRP's economy and notification systems
- ✅ **Easy Configuration** - Register dialogs in `configs/sh_dialogs.lua`
- ✅ **Admin Commands** - Spawn and manage NPCs via chat commands

## Quick Start

### Spawning NPCs

As a superadmin, use these chat commands:

```
/spawndialognpc <dialogID> [name] [model]
/listdialogs
/removenearbynpcs [radius]
```

**Examples:**
```
/spawndialognpc shopkeeper Bob the Merchant
/spawndialognpc guard City Guard models/player/police.mdl
/spawndialognpc info_npc Helper
```

## Creating Custom Dialogs

Edit `gamemode/configs/sh_dialogs.lua` and add your dialogs:

```lua
DialogNPC.RegisterDialog({
    id = "my_custom_npc",
    text = "Hello! What can I do for you?",
    options = {
        {
            id = "option1",
            text = "I need help.",
            action = function(ply, npc)
                -- Server-side code here
                DarkRP.notify(ply, 0, 4, "Here's some help!")
            end,
            nextDialog = "another_dialog"  -- Optional: chain to next dialog
        },
        {
            id = "option2",
            text = "Goodbye.",
        }
    }
})
```

## Dialog Structure

### Basic Dialog
```lua
DialogNPC.RegisterDialog({
    id = "unique_id",           -- Required: Unique identifier
    text = "What the NPC says", -- Required: Dialog text
    options = {                 -- Required: Array of response options
        {
            id = "option_id",         -- Required: Unique option ID
            text = "Player response", -- Required: What player says
            action = function(ply, npc) -- Optional: Server-side action
                -- Your code here
            end,
            nextDialog = "next_id"    -- Optional: Chain to another dialog
        }
    }
})
```

### Branching Dialog Example
```lua
-- First dialog
DialogNPC.RegisterDialog({
    id = "greeting",
    text = "Welcome! How can I help you?",
    options = {
        {
            id = "shop",
            text = "Show me your wares.",
            nextDialog = "shop_menu"  -- Chains to shop dialog
        },
        {
            id = "quest",
            text = "Any jobs available?",
            nextDialog = "quest_list"  -- Chains to quest dialog
        }
    }
})

-- Second dialog (shop)
DialogNPC.RegisterDialog({
    id = "shop_menu",
    text = "Here's what I have:",
    options = {
        {
            id = "buy_item",
            text = "Buy Health Kit - $500",
            action = function(ply, npc)
                if ply:canAfford(500) then
                    ply:addMoney(-500)
                    ply:SetHealth(100)
                    DarkRP.notify(ply, 0, 4, "Purchased!")
                else
                    DarkRP.notify(ply, 1, 4, "Can't afford!")
                end
            end,
            nextDialog = "shop_menu"  -- Return to shop
        },
        {
            id = "back",
            text = "Go back",
            nextDialog = "greeting"  -- Return to first dialog
        }
    }
})
```

## Advanced Usage

### Using DarkRP Functions

Access DarkRP economy and player functions in actions:

```lua
action = function(ply, npc)
    -- Money
    if ply:canAfford(1000) then
        ply:addMoney(-1000)
    end
    
    local money = ply:getDarkRPVar("money")
    
    -- Jobs
    local job = ply:getDarkRPVar("job")
    
    -- Notifications
    DarkRP.notify(ply, 0, 4, "Success message")  -- 0 = success
    DarkRP.notify(ply, 1, 4, "Error message")    -- 1 = error
    DarkRP.notify(ply, 2, 4, "Warning message")  -- 2 = warning
    
    -- Give items/weapons
    ply:Give("weapon_pistol")
    ply:GiveAmmo(50, "Pistol", true)
end
```

### Spawning NPCs via Code

```lua
local pos = Vector(0, 0, 0)
local ang = Angle(0, 90, 0)

local npc = DialogNPC.SpawnNPC(
    pos,
    ang,
    "shopkeeper",                      -- Dialog ID
    "Bob the Merchant",                -- NPC Name
    "models/player/group01/male_02.mdl" -- Model (optional)
)
```

### Customizing NPC Properties

When spawning, you can customize:
- `npc.DialogID` - Which dialog to use
- `npc.NPCName` - Display name above NPC
- `npc.NPCModel` - Character model
- `npc.NPCSequence` - Animation sequence (default: "idle_angry")
- `npc.UseDistance` - Interaction distance (default: 100)

## Pre-made Dialog Examples

The system includes these example dialogs:

- **shopkeeper** - Shop with items to buy
- **guard** - Guard blocking passage (requires payment)
- **info_npc** - Information/help NPC
- **quest_intro** - Quest giver NPC
- **trainer** - Gives starter equipment
- **mysterious** - Branching mysterious character dialog

Use these as templates or spawn them directly!

## Files

- `entities/entities/dialog_npc/` - Entity files (shared, init, cl_init)
- `gamemode/configs/sh_dialogs.lua` - Dialog configurations
- `gamemode/core/economy/sv_dialog_commands.lua` - Admin commands

## Tips

1. **Chain dialogs** for complex conversations using `nextDialog`
2. **Validate player state** in actions (check money, job, etc.)
3. **Use notifications** to give feedback to players
4. **Test dialogs** before deploying to live server
5. **Keep dialog text concise** for better readability
6. **Use IDs** that are descriptive (`shop_greeting` not `dialog1`)

## Troubleshooting

**NPC doesn't respond to E key:**
- Check the `UseDistance` value
- Make sure the NPC spawned correctly (`IsValid(npc)`)

**Dialog not found error:**
- Verify the dialog ID exists in `sh_dialogs.lua`
- Check console for registration messages

**Actions not executing:**
- Ensure actions are wrapped in `if SERVER then` checks
- Check console for Lua errors

## License

Part of the DarkRP gamemode.
