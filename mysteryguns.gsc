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
		replacefunc(maps\mp\zombies\_zm_powerups::init_powerups, ::init_powerups_mysteryguns);
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
		if(isDefined(level.custom_pap_validation)){
			level.original_custom_pap_validation = level.custom_pap_validation;
		}
		level.custom_pap_validation = ::instapap;
	
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
		
		player thread loopmaxammo();
		
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
	if (isDefined(self.e_afterlife_corpse))
	{
		self waittill( "player_revived" );
		wait 1.5;
	}
	
	primaries = self getweaponslistprimaries();
	
	previous = self getcurrentweapon();
	gun = previous;
	
	foreach (weapon in primaries)
	{
		self takeweapon(weapon);
	}
	
	while(previous == gun)
	{
		gun = rollgun();
	}
	
	
	if (self.hasupgraded != true)
	{
		self weapon_give( gun, 0, 0, 1 );
	}
	else
	{
		upgradedgun = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( gun, false );
		
		self weapon_give( upgradedgun, 0, 0, 1 );
	}
}

rollgun(player)
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
	hud3 settext("Weapons roll after each round. If weapon is upgraded, the next will be upgraded aswell.");
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
	betamessage setText ("TechnoOps Collection\nMystery Guns Beta\nb0.2");
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

instapap(player){
	current_weapon = player getcurrentweapon();
	current_weapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
	if ( !player maps\mp\zombies\_zm_magicbox::can_buy_weapon() && !player maps\mp\zombies\_zm_laststand::player_is_in_laststand() && !is_true( player.intermission ) || player isthrowinggrenade() && !player maps\mp\zombies\_zm_weapons::can_upgrade_weapon( current_weapon ) )
	{
		wait 0.1;
		return 0;
	}
	if ( is_true( level.pap_moving ) )
	{
		return 0;
	}
	if ( player isswitchingweapons() )
	{
		wait 0.1;
		if ( player isswitchingweapons() )
		{
			return 0;
		}
	}
	if ( !maps\mp\zombies\_zm_weapons::is_weapon_or_base_included( current_weapon ) )
	{
		return 0;
	}
	if(isDefined(level.original_custom_pap_validation)){
		if(!self [[ level.original_custom_pap_validation ]]( player )){
			return 0;
		}
	}
	current_cost = self.cost;
	player.restore_ammo = undefined;
	player.restore_clip = undefined;
	player.restore_stock = undefined;
	player_restore_clip_size = undefined;
	player.restore_max = undefined;
	upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
	if ( upgrade_as_attachment )
	{
		current_cost = self.attachment_cost;
		player.restore_ammo = 1;
		player.restore_clip = player getweaponammoclip( current_weapon );
		player.restore_clip_size = weaponclipsize( current_weapon );
		player.restore_stock = player getweaponammostock( current_weapon );
		player.restore_max = weaponmaxammo( current_weapon );
	}
	if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
	{
		current_cost = player maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );
	}
	if ( player.score < current_cost ) 
	{
		self playsound( "deny" );
		if ( isDefined( level.custom_pap_deny_vo_func ) )
		{
			player [[ level.custom_pap_deny_vo_func ]]();
		}
		else
		{
			player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
		}
		return 0;
	}
	
	self.pack_player = player;
	flag_set( "pack_machine_in_use" );
	maps\mp\_demo::bookmark( "zm_player_use_packapunch", getTime(), player );
	player maps\mp\zombies\_zm_stats::increment_client_stat( "use_pap" );
	player maps\mp\zombies\_zm_stats::increment_player_stat( "use_pap" );
	player maps\mp\zombies\_zm_score::minus_to_player_score( current_cost, 1 );
	sound = "evt_bottle_dispense";
	playsoundatposition( sound, self.origin );
	self thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
	player maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
	if ( !is_true( upgrade_as_attachment ) )
	{
		player thread do_player_general_vox( "general", "pap_wait", 10, 100 );
	}
	else
	{
		player thread do_player_general_vox( "general", "pap_wait2", 10, 100 );
	}
	self.current_weapon = current_weapon;
	upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
	
	//wait_for_player_to_take
	upgrade_weapon = upgrade_name;
	player maps\mp\zombies\_zm_stats::increment_client_stat( "pap_weapon_grabbed" );
	player maps\mp\zombies\_zm_stats::increment_player_stat( "pap_weapon_grabbed" );
	current_weapon = player getcurrentweapon();
	if ( is_player_valid( player ) && !player.is_drinking && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && !player hacker_active() )
	{
		player takeWeapon(current_weapon);
		maps\mp\_demo::bookmark( "zm_player_grabbed_packapunch", getTime(), player );
		self notify( "pap_taken" );
		player notify( "pap_taken" );
		player.pap_used = 1;
		if ( !is_true( upgrade_as_attachment ) )
		{
			player thread do_player_general_vox( "general", "pap_arm", 15, 100 );
		}
		else
		{
			player thread do_player_general_vox( "general", "pap_arm2", 15, 100 );
		}
		weapon_limit = get_player_weapon_limit( player );
		player maps\mp\zombies\_zm_weapons::take_fallback_weapon();
		primaries = player getweaponslistprimaries();
		if ( isDefined( primaries ) && primaries.size >= weapon_limit )
		{
			player maps\mp\zombies\_zm_weapons::weapon_give( upgrade_weapon );
		}
		else
		{
			player giveweapon( upgrade_weapon, 0, player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
			player givestartammo( upgrade_weapon );
		}
		player switchtoweapon( upgrade_weapon );
		if ( is_true( player.restore_ammo ) )
		{
			new_clip = player.restore_clip + ( weaponclipsize( upgrade_weapon ) - player.restore_clip_size );
			new_stock = player.restore_stock + ( weaponmaxammo( upgrade_weapon ) - player.restore_max );
			player setweaponammostock( upgrade_weapon, new_stock );
			player setweaponammoclip( upgrade_weapon, new_clip );
		}

		player.hasupgraded = true;

		player.restore_ammo = undefined;
		player.restore_clip = undefined;
		player.restore_stock = undefined;
		player.restore_max = undefined;
		player.restore_clip_size = undefined;
		player maps\mp\zombies\_zm_weapons::play_weapon_vo( upgrade_weapon );
	}

	self.current_weapon = "";
	if ( is_true( level.zombiemode_reusing_pack_a_punch ) )
	{
		self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
	}
	else
	{
		self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
	}
	self setvisibletoall();
	self.pack_player = undefined;
	flag_clear( "pack_machine_in_use" );
	return 0;	
}

init_powerups_mysteryguns()
{
    flag_init( "zombie_drop_powerups" );

    if ( isdefined( level.enable_magic ) && level.enable_magic )
        flag_set( "zombie_drop_powerups" );

    if ( !isdefined( level.active_powerups ) )
        level.active_powerups = [];

    if ( !isdefined( level.zombie_powerup_array ) )
        level.zombie_powerup_array = [];

    if ( !isdefined( level.zombie_special_drop_array ) )
        level.zombie_special_drop_array = [];

	add_zombie_powerup( "nuke", "zombie_bomb", &"ZOMBIE_POWERUP_NUKE", ::func_should_always_drop, 0, 0, 0, "misc/fx_zombie_mini_nuke_hotness" );
	add_zombie_powerup( "insta_kill", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_always_drop, 0, 0, 0, undefined, "powerup_instant_kill", "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );
	add_zombie_powerup( "full_ammo", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0 );
	add_zombie_powerup( "double_points", "zombie_x2_icon", &"ZOMBIE_POWERUP_DOUBLE_POINTS", ::func_should_always_drop, 0, 0, 0, undefined, "powerup_double_points", "zombie_powerup_point_doubler_time", "zombie_powerup_point_doubler_on" );
	add_zombie_powerup( "carpenter", "zombie_carpenter", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_always_drop, 0, 0, 0 );
	add_zombie_powerup( "fire_sale", "zombie_firesale", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_fire_sale", "zombie_powerup_fire_sale_time", "zombie_powerup_fire_sale_on" );
	add_zombie_powerup( "bonfire_sale", "zombie_pickup_bonfire", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_bon_fire", "zombie_powerup_bonfire_sale_time", "zombie_powerup_bonfire_sale_on" );
	add_zombie_powerup( "minigun", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_mini_gun", "zombie_powerup_minigun_time", "zombie_powerup_minigun_on" );
	add_zombie_powerup( "free_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_FREE_PERK", ::func_should_never_drop, 0, 0, 0 );
	add_zombie_powerup( "tesla", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_tesla", "zombie_powerup_tesla_time", "zombie_powerup_tesla_on" );
	add_zombie_powerup( "random_weapon", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 1, 0, 0 );
	add_zombie_powerup( "bonus_points_player", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 1, 0, 0 );
	add_zombie_powerup( "bonus_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 0, 0, 0 );
	add_zombie_powerup( "lose_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_LOSE_POINTS", ::func_should_never_drop, 0, 0, 1 );
	add_zombie_powerup( "lose_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
	add_zombie_powerup( "empty_clip", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
	add_zombie_powerup( "insta_kill_ug", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_instant_kill_ug", "zombie_powerup_insta_kill_ug_time", "zombie_powerup_insta_kill_ug_on", 5000 );


    if ( isdefined( level.level_specific_init_powerups ) )
        [[ level.level_specific_init_powerups ]]();

    randomize_powerups();
    level.zombie_powerup_index = 0;
    randomize_powerups();
    level.rare_powerups_active = 0;
    level.firesale_vox_firstime = 0;
    level thread powerup_hud_monitor();

    if ( isdefined( level.quantum_bomb_register_result_func ) )
    {
        [[ level.quantum_bomb_register_result_func ]]( "random_powerup", ::quantum_bomb_random_powerup_result, 5, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_zombie_grab_powerup", ::quantum_bomb_random_zombie_grab_powerup_result, 5, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_weapon_powerup", ::quantum_bomb_random_weapon_powerup_result, 60, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_bonus_or_lose_points_powerup", ::quantum_bomb_random_bonus_or_lose_points_powerup_result, 25, level.quantum_bomb_in_playable_area_validation_func );
    }

    registerclientfield( "scriptmover", "powerup_fx", 1000, 3, "int" );
}

loopmaxammo()
{
    while(1)
	{
		if ( self hasweapon( self getcurrentweapon() ) )
			self givemaxammo( self getcurrentweapon() );
		wait 0.1;
	}
}

new_weapon_spawn_think()
{
    cost = get_weapon_cost( self.zombie_weapon_upgrade );
    ammo_cost = get_ammo_cost( self.zombie_weapon_upgrade );
    is_grenade = weapontype( self.zombie_weapon_upgrade ) == "grenade";
    shared_ammo_weapon = undefined;
    second_endon = undefined;

    if ( isdefined( self.stub ) )
    {
        second_endon = "kill_trigger";
        self.first_time_triggered = self.stub.first_time_triggered;
    }

    if ( isdefined( self.stub ) && ( isdefined( self.stub.trigger_per_player ) && self.stub.trigger_per_player ) )
        self thread decide_hide_show_hint( "stop_hint_logic", second_endon, self.parent_player );
    else
        self thread decide_hide_show_hint( "stop_hint_logic", second_endon );

    if ( is_grenade )
    {
        self.first_time_triggered = 0;
        hint = get_weapon_hint( self.zombie_weapon_upgrade );
        self sethintstring( hint, cost );
    }
	else
	{
		return;
	}

    for (;;)
    {
        self waittill( "trigger", player );

        if ( !is_player_valid( player ) )
        {
            player thread ignore_triggers( 0.5 );
            continue;
        }

        if ( !player can_buy_weapon() )
        {
            wait 0.1;
            continue;
        }

        if ( isdefined( self.stub ) && ( isdefined( self.stub.require_look_from ) && self.stub.require_look_from ) )
        {
            toplayer = player get_eye() - self.origin;
            forward = -1 * anglestoright( self.angles );
            dot = vectordot( toplayer, forward );

            if ( dot < 0 )
                continue;
        }

        if ( player has_powerup_weapon() )
        {
            wait 0.1;
            continue;
        }

        player_has_weapon = player has_weapon_or_upgrade( self.zombie_weapon_upgrade );

        if ( !player_has_weapon && ( isdefined( level.weapons_using_ammo_sharing ) && level.weapons_using_ammo_sharing ) )
        {
            shared_ammo_weapon = player get_shared_ammo_weapon( self.zombie_weapon_upgrade );

            if ( isdefined( shared_ammo_weapon ) )
                player_has_weapon = 1;
        }

        if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
            player_has_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_should_we_give_raygun( player_has_weapon, player, self.zombie_weapon_upgrade );

        cost = get_weapon_cost( self.zombie_weapon_upgrade );

        if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
            cost = int( cost / 2 );

        if ( !player_has_weapon )
        {
            if ( player.score >= cost )
            {
                if ( self.first_time_triggered == 0 )
                    self show_all_weapon_buys( player, cost, ammo_cost, is_grenade );

                player maps\mp\zombies\_zm_score::minus_to_player_score( cost, 1 );
                bbprint( "zombie_uses", "playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, cost, self.zombie_weapon_upgrade, self.origin, "weapon" );
                level notify( "weapon_bought", player, self.zombie_weapon_upgrade );

                if ( self.zombie_weapon_upgrade == "riotshield_zm" )
                {
                    player maps\mp\zombies\_zm_equipment::equipment_give( "riotshield_zm" );

                    if ( isdefined( player.player_shield_reset_health ) )
                        player [[ player.player_shield_reset_health ]]();
                }
                else if ( self.zombie_weapon_upgrade == "jetgun_zm" )
                    player maps\mp\zombies\_zm_equipment::equipment_give( "jetgun_zm" );
                else
                {
                    if ( is_lethal_grenade( self.zombie_weapon_upgrade ) )
                    {
                        player takeweapon( player get_player_lethal_grenade() );
                        player set_player_lethal_grenade( self.zombie_weapon_upgrade );
                    }

                    str_weapon = self.zombie_weapon_upgrade;

                    if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
                        str_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_weapon_upgrade_check( player, str_weapon );

                    player weapon_give( str_weapon );
                }

                player maps\mp\zombies\_zm_stats::increment_client_stat( "wallbuy_weapons_purchased" );
                player maps\mp\zombies\_zm_stats::increment_player_stat( "wallbuy_weapons_purchased" );
            }
            else
            {
                play_sound_on_ent( "no_purchase" );
                player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "no_money_weapon" );
            }
        }
        else
        {
            str_weapon = self.zombie_weapon_upgrade;

            if ( isdefined( shared_ammo_weapon ) )
                str_weapon = shared_ammo_weapon;

            if ( isdefined( level.pers_upgrade_nube ) && level.pers_upgrade_nube )
                str_weapon = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_weapon_ammo_check( player, str_weapon );

            if ( isdefined( self.hacked ) && self.hacked )
            {
                if ( !player has_upgrade( str_weapon ) )
                    ammo_cost = 4500;
                else
                    ammo_cost = get_ammo_cost( str_weapon );
            }
            else if ( player has_upgrade( str_weapon ) )
                ammo_cost = 4500;
            else
                ammo_cost = get_ammo_cost( str_weapon );

            if ( isdefined( player.pers_upgrades_awarded["nube"] ) && player.pers_upgrades_awarded["nube"] )
                ammo_cost = maps\mp\zombies\_zm_pers_upgrades_functions::pers_nube_override_ammo_cost( player, self.zombie_weapon_upgrade, ammo_cost );

            if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
                ammo_cost = int( ammo_cost / 2 );

            if ( str_weapon == "riotshield_zm" )
                play_sound_on_ent( "no_purchase" );
            else if ( player.score >= ammo_cost )
            {
                if ( self.first_time_triggered == 0 )
                    self show_all_weapon_buys( player, cost, ammo_cost, is_grenade );

                if ( player has_upgrade( str_weapon ) )
                {
                    player maps\mp\zombies\_zm_stats::increment_client_stat( "upgraded_ammo_purchased" );
                    player maps\mp\zombies\_zm_stats::increment_player_stat( "upgraded_ammo_purchased" );
                }
                else
                {
                    player maps\mp\zombies\_zm_stats::increment_client_stat( "ammo_purchased" );
                    player maps\mp\zombies\_zm_stats::increment_player_stat( "ammo_purchased" );
                }

                if ( str_weapon == "riotshield_zm" )
                {
                    if ( isdefined( player.player_shield_reset_health ) )
                        ammo_given = player [[ player.player_shield_reset_health ]]();
                    else
                        ammo_given = 0;
                }
                else if ( player has_upgrade( str_weapon ) )
                    ammo_given = player ammo_give( level.zombie_weapons[str_weapon].upgrade_name );
                else
                    ammo_given = player ammo_give( str_weapon );

                if ( ammo_given )
                {
                    player maps\mp\zombies\_zm_score::minus_to_player_score( ammo_cost, 1 );
                    bbprint( "zombie_uses", "playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, ammo_cost, str_weapon, self.origin, "ammo" );
                }
            }
            else
            {
                play_sound_on_ent( "no_purchase" );

                if ( isdefined( level.custom_generic_deny_vo_func ) )
                    player [[ level.custom_generic_deny_vo_func ]]();
                else
                    player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "no_money_weapon" );
            }
        }

        if ( isdefined( self.stub ) && isdefined( self.stub.prompt_and_visibility_func ) )
            self [[ self.stub.prompt_and_visibility_func ]]( player );
    }
}
