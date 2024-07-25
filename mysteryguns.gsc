#include maps\mp\_utility;
#include maps\_utility;
#include maps\_effects;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_powerups;


main()
{
	create_dvar("enable_mysteryguns", 0);
	
	precacheshader("scorebar_zom_1");
	
	if(getDvarInt("enable_mysteryguns") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_magicbox::treasure_chest_init, ::new_treasure_chest_init);
		replacefunc(maps\mp\zombies\_zm_weapons::weapon_spawn_think, ::new_weapon_spawn_think);	

		replacefunc(maps\mp\zombies\_zm_audio_announcer::init, ::init_audio_announcer);

		replacefunc(maps\mp\zombies\_zm::round_think, ::round_think_minigame);
	}
}

init()
{
	if(getDvarInt("enable_mysteryguns") == 1)
	{
		
		level thread betaMessage();
		level.perk_purchase_limit = 9;
		level thread createlist();
		level thread onPlayerConnect();
		level.playersready = 0;
		level.mysterygunsstarted = 0;
		level thread roll_weapon_on_round_over();
		level thread introHUD();
	
//		for( i = 0; i < 8; i++ )
//		{
//			thread playerScoresHUD(i, level.players[i]);
//			wait 0.01;
//		}
	}
	
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);

        player thread onPlayerSpawned();
		
		player thread respawnPlayer();
    }
}

respawnPlayer()
{
	wait 5;
	if (self.sessionstate == "spectator")
	{
		self [[ level.spawnplayer ]]();
	}
	else
	{
	
	}
	self thread startHUDMessage();
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");

    for(;;)
    {
        self waittill("spawned_player");
        self endon("disconnect");
		
		self.lives = 999;

		if (level.mysterygunsstarted == 0)
		{
			self EnableInvulnerability();
			self thread wait_for_ready_input();
			level waittill ("end");
			self disableInvulnerability();
		}
    }
}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
		setDvar( dvar, set );
}

///////////////////////////////////////////////////
//
//
//
//			[Gamemode Specific Powerups]
//
//
//
//////////////////////////////////////////////////


new_treasure_chest_init( start_chest_name )
{

}

new_weapon_spawn_think()
{

}

new_vending_weapon_upgrade()
{

}

createlist()
{
	level.weaponlist = [];
	
	foreach (guns in level.zombie_weapons)
	{
		if (isGun(guns.weapon_name))
		{
			level.weaponlist[level.weaponlist.size] = guns.weapon_name;
		}
	}
}

isGun(gun)
{
	blockedguns = array("frag_grenade_zm", "sticky_grenade_zm", "claymore_zm", "cymbal_monkey_zm", "emp_grenade_zm", "knife_ballistic_no_melee_zm", "knife_ballistic_bowie_zm", "knife_ballistic_zm", "riotshield_zm", "jetgun_zm", "tazer_knuckles_zm", "time_bomb_zm", "tomb_shield_zm", "staff_air_upgraded2_zm", "staff_air_upgraded3_zm", "staff_air_upgraded_zm", "staff_fire_upgraded_zm", "staff_fire_upgraded2_zm", "staff_fire_upgraded3_zm", "staff_lightning_upgraded_zm", "staff_lightning2_upgraded_zm", "staff_lightning3_upgraded_zm", "staff_water_zm_cheap", "staff_water_upgraded_zm", "staff_water_upgraded2_zm", "staff_water_upgraded3_zm", "staff_revive_zm", "beacon_zm", "claymore_zm");
	blockedguns2 = array("bouncing_tomahawk_zm", "upgraded_tomahawk_zm", "alcatraz_shield_zm", "tower_trap_zm", "tower_trap_upgraded_zm", "knife_zm", "knife_zm_alcatraz", "spoon_zm_alcatraz", "spork_zm_alcatraz", "frag_grenade_zm", "claymore_zm", "willy_pete_zm", "c96_zm", "m1911_zm");
	foreach (blocked in blockedguns)
	{
		if (gun == blocked)
		{
			return 0;
		}
	}
	foreach (blocked in blockedguns2)
	{
		if (gun == blocked)
		{
			return 0;
		}
	}
	return 1;
}

changeweapon()
{
	shouldupgrade = maps\mp\zombies\_zm_weapons::can_upgrade_weapon( self getcurrentweapon() );
	
	primaries = self getweaponslistprimaries();
	
	foreach (weapon in primaries)
	{
		self takeweapon(weapon);
	}
	
	gun = rollgun();
	
	if (shouldupgrade)
	{
		self weapon_give( gun, 0, 0, 1 );
	}
	else
	{
		upgradedgun = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( gun, false );
		
		self weapon_give( upgradedgun, 0, 0, 1 );
	}
}

rollgun()
{
	rand = random(level.weaponlist);
	
	return rand;
}

roll_weapon_on_round_over()
{
	for(;;)
	{
		level waittill( "between_round_over" );
		foreach (player in get_players())
		{
			player changeweapon();
		}
	}
}

get_remaining_player()
{
	foreach (player in level.players)
	{
		if (isAlive(player))
		{
			count += 1;
			ref = player;
		}
	}
	if (count == 1)
	{
		return ref;
	}
	else
	{
		return;
	}
}

showBelowMessage(text, sound)
{	
	if(isDefined(self.belowMSD))
	{
		return;
	}
	else
	{
	
		if(isDefined(sound))
			self playsound(sound);

	
		self.belowMSG = newclienthudelem( self );
		self.belowMSG.alignx = "center";
		self.belowMSG.aligny = "bottom";
		self.belowMSG.horzalign = "center";
		self.belowMSG.vertalign = "bottom";
		self.belowMSG.y -= 10;
    
		self.belowMSG.foreground = 1;
		self.belowMSG.fontscale = 4;
		self.belowMSG.alpha = 0;
		self.belowMSG.hidewheninmenu = 1;
		self.belowMSG.font = "default";

		self.belowMSG settext( text );
		self.belowMSG.color = ( 1, 1, 1 );

		self.belowMSG changefontscaleovertime( 0.25 );
		self.belowMSG fadeovertime( 0.25 );
		self.belowMSG.alpha = 1;
		self.belowMSG.fontscale = 2;
    
		wait 3;
    
		self.belowMSG changefontscaleovertime( 0.25 );
		self.belowMSG fadeovertime( 0.25 );
		self.belowMSG.alpha = 0;
		self.belowMSG.fontscale = 4;
		wait 1.1;
		self.belowMSG destroy();
	}
}

init_audio_announcer()
{
    game["zmbdialog"] = [];
    game["zmbdialog"]["prefix"] = "vox_zmba";
    createvox( "boxmove", "event_magicbox" );
    createvox( "dogstart", "event_dogstart" );
    thread init_gamemodespecificvox( getdvar( #"ui_gametype" ), getdvar( #"ui_zm_mapstartlocation" ) );
    level.allowzmbannouncer = 1;
}

round_think_minigame( restart )
{
	if(level.mysterygunsstarted == 0)
	{
		level waittill ("end");
	}
	
	if ( !isdefined( restart ) )
        restart = 0;

/#
    println( "ZM >> round_think start" );
#/
    level endon( "end_round_think" );

    if ( !( isdefined( restart ) && restart ) )
    {
        if ( isdefined( level.initial_round_wait_func ) )
            [[ level.initial_round_wait_func ]]();

        if ( !( isdefined( level.host_ended_game ) && level.host_ended_game ) )
        {
            players = get_players();

            foreach ( player in players )
            {
                if ( !( isdefined( player.hostmigrationcontrolsfrozen ) && player.hostmigrationcontrolsfrozen ) )
                {
                    player freezecontrols( 0 );
/#
                    println( " Unfreeze controls 8" );
#/
                }

                player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            }
        }
    }

    setroundsplayed( level.round_number );

    for (;;)
    {
        maxreward = 50 * level.round_number;

        if ( maxreward > 500 )
            maxreward = 500;

        level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
        level.pro_tips_start_time = gettime();
        level.zombie_last_run_time = gettime();

        if ( isdefined( level.zombie_round_change_custom ) )
            [[ level.zombie_round_change_custom ]]();
        else
        {
            level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
            round_one_up();
        }

        maps\mp\zombies\_zm_powerups::powerup_round_start();
        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_blockers::rebuild_barrier_reward_reset );

        if ( !( isdefined( level.headshots_only ) && level.headshots_only ) && !restart )
            level thread award_grenades_for_survivors();

        bbprint( "zombie_rounds", "round %d player_count %d", level.round_number, players.size );
/#
        println( "ZM >> round_think, round=" + level.round_number + ", player_count=" + players.size );
#/
        level.round_start_time = gettime();

        while ( level.zombie_spawn_locations.size <= 0 )
            wait 0.1;

        level thread [[ level.round_spawn_func ]]();
        level notify( "start_of_round" );
        recordzombieroundstart();
        players = getplayers();

        for ( index = 0; index < players.size; index++ )
        {
            zonename = players[index] get_current_zone();

            if ( isdefined( zonename ) )
                players[index] recordzombiezone( "startingZone", zonename );
        }

        if ( isdefined( level.round_start_custom_func ) )
            [[ level.round_start_custom_func ]]();

        [[ level.round_wait_func ]]();
        level.first_round = 0;
        level notify( "end_of_round" );
//        level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_end" );
		level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
        uploadstats();

        if ( isdefined( level.round_end_custom_logic ) )
            [[ level.round_end_custom_logic ]]();

        players = get_players();

        if ( isdefined( level.no_end_game_check ) && level.no_end_game_check )
        {
            level thread last_stand_revive();
        }
        else if ( 1 != players.size )
            level thread spectators_respawn();

        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_pers_upgrades_system::round_end );
        timer = level.zombie_vars["zombie_spawn_delay"];

        if ( timer > 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
        else if ( timer < 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = 0.08;

        if ( level.gamedifficulty == 0 )
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier_easy"];
        else
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];

        level.round_number++;

        if ( 255 < level.round_number )
            level.round_number = 255;

        setroundsplayed( level.round_number );
        matchutctime = getutc();
        players = get_players();

        foreach ( player in players )
        {
            if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
                player maps\mp\zombies\_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );

            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            player maps\mp\zombies\_zm_stats::update_playing_utc_time( matchutctime );
        }

        check_quickrevive_for_hotjoin();
        level round_over();
        level notify( "between_round_over" );
        restart = 0;
    }
}

wait_for_ready_input()
{
	level endon ("end");
	level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
	self waittill ("can_readyup");
	while(1)
	{
		if(self meleebuttonpressed() && self adsbuttonpressed())
		{
			if (self.voted == 0)
			{
				level.playersready += 1;
				self.voted = 1;
				level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
				if (level.playersready == level.players.size)
				{
					wait 1;
					level.mysterygunsstarted = 1;
					level thread minigames_timer_hud();
					foreach (player in level.players)
					{
						player disableInvulnerability();
					}
					level notify ("end");
				}
			}
		}
		wait 0.01;
	}
}

introHUD()
{
	flag_wait( "initial_blackscreen_passed" );
	level.introHUD = newhudelem();
	level.introHUD.x = 0;
	level.introHUD.y -= 20;
	level.introHUD.alpha = 1;
	level.introHUD.alignx = "center";
	level.introHUD.aligny = "bottom";
    level.introHUD.horzalign = "user_center";
    level.introHUD.vertalign = "user_bottom";
	level.introHUD.foreground = 0;
	level.introHUD.fontscale = 1.5;
	level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
	level waittill ("end");
	level.introHUD fadeovertime( 0.25 );
	level.introHUD.alpha = 0;
	level.introHUD destroy();
}

playerScoresHUD(index, ref)
{
	y = (index * 20) + -60;
	
	namebg = newhudelem();;
	namebg.alignx = "left";
	namebg.aligny = "center";
	namebg.horzalign = "user_left";
	namebg.vertalign = "user_center";
	namebg.x -= 10;
	namebg.y += y - 4;
	namebg.fontscale = 2;
	namebg.alpha = 0;
	namebg.color = ( 1, 1, 0 );
	namebg.hidewheninmenu = 1;
	namebg.foreground = 0;
	namebg setShader("scorebar_zom_1", 124, 32);

	nameHUD = newhudelem();;
	nameHUD.x = 10;
	nameHUD.y += y;
	nameHUD.alpha = 0;
	nameHUD.alignx = "left";
	nameHUD.aligny = "center";
	nameHUD.horzalign = "user_left";
	nameHUD.vertalign = "user_center";
	nameHUD.fontscale = 0;
	nameHUD.foreground = 0;
	nameHUD setText (ref.name);

	scoreHUD = newhudelem();;
	scoreHUD.x = 10;
	scoreHUD.y = nameHUD.y + 10;
	scoreHUD.alpha = 0;
	scoreHUD.alignx = "left";
	scoreHUD.aligny = "center";
	scoreHUD.horzalign = "user_left";
	scoreHUD.vertalign = "user_center";
	scoreHUD.fontscale = 0;
	scoreHUD.foreground = 0;
	scoreHUD.label = ("");
	
	while(1)
	{
		ref = level.players[index];
		scoreHUD setValue (ref.weaponlevel);
		
		if(ref != oldref)
		{
			nameHUD setText (ref.name);
			oldref = ref;
		}

		if ( (ref.weaponlevel == level.weaponlist.size - 1) && isDefined(level.players[index]))
		{
			namebg.alpha = 1;
		}
		else
		{
			namebg.alpha = 0;
		}
		
		if (level.mysterygunsstarted == 0)
		{
			scoreHUD.alpha = 0;
			nameHUD.alpha = 0;
		}
		else
		{
			if (isDefined(level.players[index]))
			{
				scoreHUD.alpha = 1;
				nameHUD.alpha = 1;
			}
			else
			{
				scoreHUD.alpha = 0;
				nameHUD.alpha = 0;
			}
		}
		wait 0.1;
	}
}

minigames_timer_hud()
{
	hud = newHudElem();
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "user_left";
	hud.vertalign = "user_top";
	hud.x = 25;
	hud.y += 24;
	hud.fontscale = 2;
	hud.alpha = 0;
	hud.color = ( 1, 1, 1 );
	hud.hidewheninmenu = 1;
	hud.foreground = 0;
	hud.label = &"";

	hud endon("death");

	hud.alpha = 1;

	hud thread set_time_frozen_on_end_game();

	if ( !flag( "initial_blackscreen_passed" ) )
	{
		hud set_time_frozen(0, "initial_blackscreen_passed");
	}

	if ( getDvar( "g_gametype" ) == "zgrief" )
	{
		hud set_time_frozen(0);
	}

	hud setTimerUp(0);
	hud.start_time = getTime();
	level.timer_hud_start_time = hud.start_time;
	level waittill ("end_game");
	hud destroy();
}

startHUDMessage()
{
	flag_wait( "initial_blackscreen_passed" );
	
	hud = newClientHudElem(self);
	hud.alignx = "center";
	hud.aligny = "top";
	hud.horzalign = "user_center";
	hud.vertalign = "user_top";
	hud.x = 0;
	hud.y += 24;
	hud.fontscale = 3;
	hud.alpha = 0;
	hud.color = ( 1, 1, 1 );
	hud.hidewheninmenu = 1;
	hud.foreground = 1;
	hud settext("TechnoOps Collection:");
	hud.fontscale = 3;
	hud changefontscaleovertime( 1 );
    hud fadeovertime( 1 );
    hud.alpha = 1;
    hud.fontscale = 1.5;

	wait 1;

	hud2 = newClientHudElem(self);
	hud2.alignx = "center";
	hud2.aligny = "top";
	hud2.horzalign = "user_center";
	hud2.vertalign = "user_top";
	hud2.x = 0;
	hud2.y += 42;
	hud2.fontscale = 8;
	hud2.alpha = 0;
	hud2.color = ( 1, 1, 1 );
	hud2.hidewheninmenu = 1;
	hud2.foreground = 1;
	hud2 settext("Mystery Guns");
	hud2.fontscale = 8;
	hud2 changefontscaleovertime( 1 );
    hud2 fadeovertime( 1 );
    hud2.alpha = 1;
    hud2.fontscale = 4;

	wait 1;
	
	hud3 = newClientHudElem(self);
	hud3.alignx = "center";
	hud3.aligny = "top";
	hud3.horzalign = "user_center";
	hud3.vertalign = "user_top";
	hud3.x = 0;
	hud3.y += 90;
	hud3.fontscale = 2;
	hud3.alpha = 0;
	hud3.color = ( 1, 1, 1 );
	hud3.hidewheninmenu = 1;
	hud3.foreground = 1;
	hud3 settext("Get a specified amount of kills to advance. First to complete the ladder wins!");
	hud3.fontscale = 2;
	hud3 changefontscaleovertime( 1 );
    hud3 fadeovertime( 1 );
    hud3.alpha = 1;
    hud3.fontscale = 1.5;
	wait 1;
	self notify ("can_readyup");

    if(level.mysterygunsstarted == 0)
	{
		level waittill ("end");
	}
	else
	{
		wait 3.25;
	}

    hud changefontscaleovertime( 1 );
    hud fadeovertime( 1 );
    hud.alpha = 0;
    hud.fontscale = 4;
//    wait 1;
	
    hud2 changefontscaleovertime( 1 );
    hud2 fadeovertime( 1 );
    hud2.alpha = 0;
    hud2.fontscale = 6;
//    wait 1;
	
    hud3 changefontscaleovertime( 1 );
    hud3 fadeovertime( 1 );
    hud3.alpha = 0;
    hud3.fontscale = 2;
    wait 1;
	
	hud destroy();
	hud2 destroy();
	hud3 destroy();
}

betaMessage()
{
	betamessage = newhudelem();
	betamessage.x -= 15;
	betamessage.y -= 20;
	betamessage.alpha = 0.2;
    betamessage.horzalign = "right";
    betamessage.vertalign = "top";
	betamessage.foreground = 1;
	betamessage setText ("TechnoOps Collection\nMystery Guns Beta\nb0.8");
}

set_time_frozen_on_end_game()
{
	level endon("intermission");

	level waittill_any("end_game", "freeze_timers");

	time = int((getTime() - self.start_time) / 1000);

	self set_time_frozen(time, "forever");
}

set_time_frozen(time, endon_notify)
{
	if ( isDefined( endon_notify ) )
	{
		level endon( endon_notify );
	}
	else if ( getDvar( "g_gametype" ) == "zgrief" )
	{
		level endon( "restart_round_start" );
	}
	else
	{
		level endon( "start_of_round" );
	}

	self endon( "death" );

	if(time != 0)
	{
		time -= 0.5; // need to set it below the number or it shows the next number
	}

	while (1)
	{
		if(time == 0)
		{
			self setTimerUp(time);
		}
		else
		{
			self setTimer(time);
		}

		wait 0.5;
	}
}