// Copyright information
// File originally from https://github.com/JeffG05/emoji_picker

final Map<String, String> smileys = Map.fromIterables([':grinning:',':smiley:',':smile:',':grin:',':laughing:',':sweat_smile:',':rofl:',':joy:',':slight_smile:',':upside_down:',':wink:',':blush:',':innocent:',':smiling_face_with_3_hearts:',':heart_eyes:',':star_struck:',':kissing_heart:',':kissing:',':kissing_closed_eyes:',':kissing_smiling_eyes:',':yum:',':stuck_out_tongue:',':stuck_out_tongue_winking_eye:',':zany_face:',':stuck_out_tongue_closed_eyes:',':money_mouth:',':hugging:',':face_with_hand_over_mouth:',':shushing_face:',':thinking:',':zipper_mouth:',':face_with_raised_eyebrow:',':neutral_face:',':expressionless:',':no_mouth:',':smirk:',':unamused:',':rolling_eyes:',':grimacing:',':lying_face:',':relieved:',':pensive:',':sleepy:',':drooling_face:',':sleeping:',':mask:',':thermometer_face:',':head_bandage:',':nauseated_face:',':face_vomiting:',':sneezing_face:',':hot_face:',':cold_face:',':woozy_face:',':dizzy_face:',':exploding_head:',':cowboy:',':partying_face:',':sunglasses:',':nerd:',':face_with_monocle:',':confused:',':worried:',':slight_frown:',':frowning2:',':person_rowing_boat:',':hushed:',':astonished:',':flushed:',':pleading_face:',':frowning:',':anguished:',':fearful:',':cold_sweat:',':disappointed_relieved:',':cry:',':sob:',':scream:',':confounded:',':persevere:',':disappointed:',':sweat:',':weary:',':tired_face:',':triumph:',':rage:',':angry:',':face_with_symbols_over_mouth:',':smiling_imp:',':imp:',':skull:',':poop:',':clown:',':japanese_ogre:',':japanese_goblin:',':ghost:',':alien:',':space_invader:',':robot:',':smiley_cat:',':smile_cat:',':joy_cat:',':heart_eyes_cat:',':smirk_cat:',':kissing_cat:',':scream_cat:',':crying_cat_face:',':pouting_cat:',':kiss:',':wave:',':raised_back_of_hand:',':raised_hand:',':vulcan:',':ok_hand:',':fingers_crossed:',':love_you_gesture:',':metal:',':call_me:',':point_left:',':point_right:',':point_up_2:',':middle_finger:',':point_down:',':thumbsup:',':thumbsdown:',':fist:',':punch:',':left_facing_fist:',':right_facing_fist:',':clap:',':raised_hands:',':open_hands:',':palms_up_together:',':handshake:',':pray:',':nail_care:',':selfie:',':muscle:',':leg:',':foot:',':ear:',':nose:',':brain:',':tooth:',':bone:',':eyes:',':tongue:',':lips:',':baby:',':child:',':boy:',':girl:',':adult:',':man:',':bearded_person:',':blond-haired_man:',':man_red_haired:',':man_curly_haired:',':man_white_haired:',':man_bald:',':woman:',':blond-haired_woman:',':woman_red_haired:',':woman_curly_haired:',':woman_white_haired:',':woman_bald:',':older_adult:',':older_man:',':older_woman:',':man_frowning:',':woman_frowning:',':man_pouting:',':woman_pouting:',':man_gesturing_no:',':woman_gesturing_no:',':man_gesturing_ok:',':woman_gesturing_ok:',':man_tipping_hand:',':woman_tipping_hand:',':man_raising_hand:',':woman_raising_hand:',':man_bowing:',':woman_bowing:',':man_facepalming:',':woman_facepalming:',':man_shrugging:',':woman_shrugging:',':man_health_worker:',':woman_health_worker:',':man_student:',':woman_student:',':man_teacher:',':woman_teacher:',':man_judge:',':woman_judge:',':man_farmer:',':woman_farmer:',':man_cook:',':woman_cook:',':man_mechanic:',':woman_mechanic:',':man_factory_worker:',':woman_factory_worker:',':man_office_worker:',':woman_office_worker:',':man_scientist:',':woman_scientist:',':man_technologist:',':woman_technologist:',':man_singer:',':woman_singer:',':man_artist:',':woman_artist:',':man_pilot:',':woman_pilot:',':man_astronaut:',':woman_astronaut:',':man_firefighter:',':woman_firefighter:',':man_police_officer:',':woman_police_officer:',':man_detective:',':woman_detective:',':man_guard:',':woman_guard:',':man_construction_worker:',':woman_construction_worker:',':prince:',':princess:',':man_wearing_turban:',':woman_wearing_turban:',':man_with_chinese_cap:',':woman_with_headscarf:',':man_in_tuxedo:',':bride_with_veil:',':pregnant_woman:',':breast_feeding:',':angel:',':santa:',':mrs_claus:',':man_superhero:',':woman_superhero:',':man_supervillain:',':woman_supervillain:',':man_mage:',':woman_mage:',':man_fairy:',':woman_fairy:',':man_vampire:',':woman_vampire:',':merman:',':mermaid:',':man_elf:',':woman_elf:',':man_genie:',':woman_genie:',':man_zombie:',':woman_zombie:',':man_getting_face_massage:',':woman_getting_face_massage:',':man_getting_haircut:',':woman_getting_haircut:',':man_walking:',':woman_walking:',':man_running:',':woman_running:',':dancer:',':man_dancing:',':men_with_bunny_ears_partying:',':women_with_bunny_ears_partying:',':man_in_steamy_room:',':woman_in_steamy_room:',':person_in_lotus_position:',':two_women_holding_hands:',':couple:',':two_men_holding_hands:',':couplekiss:',':couple_with_heart:',':couple_mm:',':couple_ww:',':family:',':family_man_woman_boy:',':family_mwg:',':family_mwgb:',':family_mwbb:',':family_mwgg:',':family_mmb:',':family_mmg:',':family_mmgb:',':family_mmbb:',':family_mmgg:',':family_wwb:',':family_wwg:',':family_wwgb:',':family_wwbb:',':family_wwgg:',':family_man_boy:',':family_man_boy_boy:',':family_man_girl:',':family_man_girl_boy:',':family_man_girl_girl:',':family_woman_boy:',':family_woman_boy_boy:',':family_woman_girl:',':family_woman_girl_boy:',':family_woman_girl_girl:',':bust_in_silhouette:',':busts_in_silhouette:',':footprints:',':luggage:',':closed_umbrella:',':thread:',':yarn:',':eyeglasses:',':goggles:',':lab_coat:',':necktie:',':shirt:',':jeans:',':scarf:',':gloves:',':coat:',':socks:',':dress:',':kimono:',':bikini:',':womans_clothes:',':purse:',':handbag:',':pouch:',':school_satchel:',':mans_shoe:',':athletic_shoe:',':hiking_boot:',':womans_flat_shoe:',':high_heel:',':sandal:',':boot:',':crown:',':womans_hat:',':tophat:',':mortar_board:',':billed_cap:',':lipstick:',':ring:',':briefcase:',], ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇','🥰','😍','🤩','😘','😗','😚','😙','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄','😬','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','🤯','🤠','🥳','😎','🤓','🧐','😕','😟','🙁','☹️','🚣','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','😤','😡','😠','🤬','😈','👿','💀','💩','🤡','👹','👺','👻','👽','👾','🤖','😺','😸','😹','😻','😼','😽','🙀','😿','😾','💋','👋','🤚','✋','🖖','👌','🤞','🤟','🤘','🤙','👈','👉','👆','🖕','👇','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','💅','🤳','💪','🦵','🦶','👂','👃','🧠','🦷','🦴','👀','👅','👄','👶','🧒','👦','👧','🧑','👨','🧔','👱‍♂️','👨‍🦰','👨‍🦱','👨‍🦳','👨‍🦲','👩','👱‍♀️','👩‍🦰','👩‍🦱','👩‍🦳','👩‍🦲','🧓','👴','👵','🙍‍♂️','🙍‍♀️','🙎‍♂️','🙎‍♀️','🙅‍♂️','🙅‍♀️','🙆‍♂️','🙆‍♀️','💁‍♂️','💁‍♀️','🙋‍♂️','🙋‍♀️','🙇‍♂️','🙇‍♀️','🤦‍♂️','🤦‍♀️','🤷‍♂️','🤷‍♀️','👨‍⚕️','👩‍⚕️','👨‍🎓','👩‍🎓','👨‍🏫','👩‍🏫','👨‍⚖️','👩‍⚖️','👨‍🌾','👩‍🌾','👨‍🍳','👩‍🍳','👨‍🔧','👩‍🔧','👨‍🏭','👩‍🏭','👨‍💼','👩‍💼','👨‍🔬','👩‍🔬','👨‍💻','👩‍💻','👨‍🎤','👩‍🎤','👨‍🎨','👩‍🎨','👨‍✈️','👩‍✈️','👨‍🚀','👩‍🚀','👨‍🚒','👩‍🚒','👮‍♂️','👮‍♀️','🕵️‍♂️','🕵️‍♀️','💂‍♂️','💂‍♀️','👷‍♂️','👷‍♀️','🤴','👸','👳‍♂️','👳‍♀️','👲','🧕','🤵','👰','🤰','🤱','👼','🎅','🤶','🦸‍♂️','🦸‍♀️','🦹‍♂️','🦹‍♀️','🧙‍♂️','🧙‍♀️','🧚‍♂️','🧚‍♀️','🧛‍♂️','🧛‍♀️','🧜‍♂️','🧜‍♀️','🧝‍♂️','🧝‍♀️','🧞‍♂️','🧞‍♀️','🧟‍♂️','🧟‍♀️','💆‍♂️','💆‍♀️','💇‍♂️','💇‍♀️','🚶‍♂️','🚶‍♀️','🏃‍♂️','🏃‍♀️','💃','🕺','👯‍♂️','👯‍♀️','🧖‍♂️','🧖‍♀️','🧘','👭','👫','👬','💏','💑','👨‍❤️‍👨','👩‍❤️‍👩','👪','👨‍👩‍👦','👨‍👩‍👧','👨‍👩‍👧‍👦','👨‍👩‍👦‍👦','👨‍👩‍👧‍👧','👨‍👨‍👦','👨‍👨‍👧','👨‍👨‍👧‍👦','👨‍👨‍👦‍👦','👨‍👨‍👧‍👧','👩‍👩‍👦','👩‍👩‍👧','👩‍👩‍👧‍👦','👩‍👩‍👦‍👦','👩‍👩‍👧‍👧','👨‍👦','👨‍👦‍👦','👨‍👧','👨‍👧‍👦','👨‍👧‍👧','👩‍👦','👩‍👦‍👦','👩‍👧','👩‍👧‍👦','👩‍👧‍👧','👤','👥','👣','🧳','🌂','🧵','🧶','👓','🥽','🥼','👔','👕','👖','🧣','🧤','🧥','🧦','👗','👘','👙','👚','👛','👜','👝','🎒','👞','👟','🥾','🥿','👠','👡','👢','👑','👒','🎩','🎓','🧢','💄','💍','💼',]);
final Map<String, String> activities = Map.fromIterables([':man_climbing:',':woman_climbing:',':horse_racing:',':snowboarder:',':man_golfing:',':woman_golfing:',':man_surfing:',':woman_surfing:',':man_rowing_boat:',':woman_rowing_boat:',':man_swimming:',':woman_swimming:',':man_bouncing_ball:',':woman_bouncing_ball:',':man_lifting_weights:',':woman_lifting_weights:',':man_biking:',':woman_biking:',':man_mountain_biking:',':woman_mountain_biking:',':man_cartwheeling:',':woman_cartwheeling:',':man_playing_water_polo:',':woman_playing_water_polo:',':man_playing_handball:',':woman_playing_handball:',':man_juggling:',':woman_juggling:',':man_in_lotus_position:',':woman_in_lotus_position:',':circus_tent:',':skateboard:',':ticket:',':trophy:',':medal:',':first_place:',':second_place:',':third_place:',':soccer:',':baseball:',':softball:',':basketball:',':volleyball:',':football:',':rugby_football:',':tennis:',':flying_disc:',':bowling:',':cricket_game:',':field_hockey:',':hockey:',':lacrosse:',':ping_pong:',':badminton:',':boxing_glove:',':martial_arts_uniform:',':golf:',':fishing_pole_and_fish:',':running_shirt_with_sash:',':ski:',':sled:',':curling_stone:',':dart:',':8ball:',':video_game:',':slot_machine:',':game_die:',':jigsaw:',':performing_arts:',':art:',':thread:',':yarn:',':musical_score:',':microphone:',':headphones:',':saxophone:',':guitar:',':musical_keyboard:',':trumpet:',':violin:',':drum:',':clapper:',':bow_and_arrow:',], ['🧗‍♂️','🧗‍♀️','🏇','🏂','🏌️‍♂️','🏌️‍♀️','🏄‍♂️','🏄‍♀️','🚣‍♂️','🚣‍♀️','🏊‍♂️','🏊‍♀️','⛹️‍♂️','⛹️‍♀️','🏋️‍♂️','🏋️‍♀️','🚴‍♂️','🚴‍♀️','🚵‍♂️','🚵‍♀️','🤸‍♂️','🤸‍♀️','🤽‍♂️','🤽‍♀️','🤾‍♂️','🤾‍♀️','🤹‍♂️','🤹‍♀️','🧘‍♂️','🧘‍♀️','🎪','🛹','🎫','🏆','🏅','🥇','🥈','🥉','⚽','⚾','🥎','🏀','🏐','🏈','🏉','🎾','🥏','🎳','🏏','🏑','🏒','🥍','🏓','🏸','🥊','🥋','⛳','🎣','🎽','🎿','🛷','🥌','🎯','🎱','🎮','🎰','🎲','🧩','🎭','🎨','🧵','🧶','🎼','🎤','🎧','🎷','🎸','🎹','🎺','🎻','🥁','🎬','🏹',]);
final Map<String, String> animals = Map.fromIterables([':dog:',':cat:',':mouse:',':hamster:',':rabbit:',':fox:',':bear:',':panda_face:',':koala:',':tiger:',':lion_face:',':cow:',':pig:',':pig_nose:',':frog:',':monkey_face:',':see_no_evil:',':hear_no_evil:',':speak_no_evil:',':monkey:',':boom:',':dizzy:',':sweat_drops:',':dash:',':gorilla:',':dog2:',':poodle:',':wolf:',':raccoon:',':cat2:',':tiger2:',':leopard:',':horse:',':racehorse:',':unicorn:',':zebra:',':ox:',':water_buffalo:',':cow2:',':pig2:',':boar:',':ram:',':sheep:',':goat:',':dromedary_camel:',':camel:',':llama:',':giraffe:',':elephant:',':rhino:',':hippopotamus:',':mouse2:',':rat:',':rabbit2:',':hedgehog:',':bat:',':kangaroo:',':badger:',':feet:',':turkey:',':chicken:',':rooster:',':hatching_chick:',':baby_chick:',':hatched_chick:',':bird:',':penguin:',':eagle:',':duck:',':swan:',':owl:',':peacock:',':parrot:',':crocodile:',':turtle:',':lizard:',':snake:',':dragon_face:',':dragon:',':sauropod:',':t_rex:',':whale:',':whale2:',':dolphin:',':fish:',':tropical_fish:',':blowfish:',':shark:',':octopus:',':shell:',':snail:',':butterfly:',':bug:',':ant:',':bee:',':beetle:',':cricket:',':scorpion:',':mosquito:',':microbe:',':bouquet:',':cherry_blossom:',':white_flower:',':rose:',':wilted_rose:',':hibiscus:',':sunflower:',':blossom:',':tulip:',':seedling:',':evergreen_tree:',':deciduous_tree:',':palm_tree:',':cactus:',':ear_of_rice:',':herb:',':four_leaf_clover:',':maple_leaf:',':fallen_leaf:',':leaves:',':mushroom:',':chestnut:',':crab:',':lobster:',':shrimp:',':squid:',':earth_africa:',':earth_americas:',':earth_asia:',':globe_with_meridians:',':new_moon:',':waxing_crescent_moon:',':first_quarter_moon:',':waxing_gibbous_moon:',':full_moon:',':waning_gibbous_moon:',':last_quarter_moon:',':waning_crescent_moon:',':crescent_moon:',':new_moon_with_face:',':first_quarter_moon_with_face:',':last_quarter_moon_with_face:',':full_moon_with_face:',':sun_with_face:',':star:',':star2:',':stars:',':partly_sunny:',':rainbow:',':umbrella:',':zap:',':snowman:',':fire:',':droplet:',':ocean:',':christmas_tree:',':sparkles:',':tanabata_tree:',':bamboo:',], ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒','💥','💫','💦','💨','🦍','🐕','🐩','🐺','🦝','🐈','🐅','🐆','🐴','🐎','🦄','🦓','🐂','🐃','🐄','🐖','🐗','🐏','🐑','🐐','🐪','🐫','🦙','🦒','🐘','🦏','🦛','🐁','🐀','🐇','🦔','🦇','🦘','🦡','🐾','🦃','🐔','🐓','🐣','🐤','🐥','🐦','🐧','🦅','🦆','🦢','🦉','🦚','🦜','🐊','🐢','🦎','🐍','🐲','🐉','🦕','🦖','🐳','🐋','🐬','🐟','🐠','🐡','🦈','🐙','🐚','🐌','🦋','🐛','🐜','🐝','🐞','🦗','🦂','🦟','🦠','💐','🌸','💮','🌹','🥀','🌺','🌻','🌼','🌷','🌱','🌲','🌳','🌴','🌵','🌾','🌿','🍀','🍁','🍂','🍃','🍄','🌰','🦀','🦞','🦐','🦑','🌍','🌎','🌏','🌐','🌑','🌒','🌓','🌔','🌕','🌖','🌗','🌘','🌙','🌚','🌛','🌜','🌝','🌞','⭐','🌟','🌠','⛅','🌈','☔','⚡','⛄','🔥','💧','🌊','🎄','✨','🎋','🎍',]);
final Map<String, String> flags = Map.fromIterables([':checkered_flag:',':triangular_flag_on_post:',':crossed_flags:',':flag_black:',':rainbow_flag:',':pirate_flag:',':flag_ac:',':flag_ad:',':flag_ae:',':flag_af:',':flag_ag:',':flag_ai:',':flag_al:',':flag_am:',':flag_ao:',':flag_aq:',':flag_ar:',':flag_as:',':flag_at:',':flag_au:',':flag_aw:',':flag_ax:',':flag_az:',':flag_ba:',':flag_bb:',':flag_bd:',':flag_be:',':flag_bf:',':flag_bg:',':flag_bh:',':flag_bi:',':flag_bj:',':flag_bm:',':flag_bn:',':flag_bo:',':flag_br:',':flag_bs:',':flag_bt:',':flag_bv:',':flag_bw:',':flag_by:',':flag_bz:',':flag_ca:',':flag_cc:',':flag_cd:',':flag_cf:',':flag_cg:',':flag_ch:',':flag_ci:',':flag_ck:',':flag_cl:',':flag_cm:',':flag_cn:',':flag_co:',':flag_cp:',':flag_cr:',':flag_cu:',':flag_cv:',':flag_cw:',':flag_cx:',':flag_cy:',':flag_cz:',':flag_de:',':flag_dj:',':flag_dk:',':flag_dm:',':flag_do:',':flag_dz:',':flag_ec:',':flag_ee:',':flag_eg:',':flag_er:',':flag_es:',':flag_et:',':flag_eu:',':flag_fi:',':flag_fj:',':flag_fm:',':flag_fo:',':flag_fr:',':flag_ga:',':flag_gb:',':flag_gd:',':flag_ge:',':flag_gg:',':flag_gh:',':flag_gi:',':flag_gl:',':flag_gm:',':flag_gn:',':flag_gq:',':flag_gr:',':flag_gt:',':flag_gu:',':flag_gw:',':flag_gy:',':flag_hk:',':flag_hm:',':flag_hn:',':flag_hr:',':flag_ht:',':flag_hu:',':flag_ic:',':flag_id:',':flag_ie:',':flag_il:',':flag_im:',':flag_in:',':flag_io:',':flag_iq:',':flag_ir:',':flag_is:',':flag_it:',':flag_je:',':flag_jm:',':flag_jo:',':flag_jp:',':flag_ke:',':flag_kg:',':flag_kh:',':flag_ki:',':flag_km:',':flag_kn:',':flag_kp:',':flag_kr:',':flag_kw:',':flag_ky:',':flag_kz:',':flag_la:',':flag_lb:',':flag_lc:',':flag_li:',':flag_lk:',':flag_lr:',':flag_ls:',':flag_lt:',':flag_lu:',':flag_lv:',':flag_ly:',':flag_ma:',':flag_mc:',':flag_md:',':flag_me:',':flag_mg:',':flag_mh:',':flag_mk:',':flag_ml:',':flag_mm:',':flag_mn:',':flag_mo:',':flag_mp:',':flag_mr:',':flag_ms:',':flag_mt:',':flag_mu:',':flag_mv:',':flag_mw:',':flag_mx:',':flag_my:',':flag_mz:',':flag_na:',':flag_ne:',':flag_nf:',':flag_ng:',':flag_ni:',':flag_nl:',':flag_no:',':flag_np:',':flag_nr:',':flag_nu:',':flag_nz:',':flag_om:',':flag_pa:',':flag_pe:',':flag_pf:',':flag_pg:',':flag_ph:',':flag_pk:',':flag_pl:',':flag_pn:',':flag_pr:',':flag_ps:',':flag_pt:',':flag_pw:',':flag_py:',':flag_qa:',':flag_ro:',':flag_rs:',':flag_ru:',':flag_rw:',':flag_sa:',':flag_sb:',':flag_sc:',':flag_sd:',':flag_se:',':flag_sg:',':flag_sh:',':flag_si:',':flag_sj:',':flag_sk:',':flag_sl:',':flag_sm:',':flag_sn:',':flag_so:',':flag_sr:',':flag_ss:',':flag_st:',':flag_sv:',':flag_sx:',':flag_sy:',':flag_sz:',':flag_ta:',':flag_tc:',':flag_td:',':flag_tg:',':flag_th:',':flag_tj:',':flag_tk:',':flag_tl:',':flag_tm:',':flag_tn:',':flag_to:',':flag_tr:',':flag_tt:',':flag_tv:',':flag_tw:',':flag_tz:',':flag_ua:',':flag_ug:',':flag_um:',':united_nations:',':flag_us:',':flag_uy:',':flag_uz:',':flag_va:',':flag_vc:',':flag_ve:',':flag_vg:',':flag_vi:',':flag_vn:',':flag_vu:',':flag_ws:',':flag_ye:',':flag_za:',':flag_zm:',':flag_zw:',], ['🏁','🚩','🎌','🏴','🏳️‍🌈','🏴‍☠️','🇦🇨','🇦🇩','🇦🇪','🇦🇫','🇦🇬','🇦🇮','🇦🇱','🇦🇲','🇦🇴','🇦🇶','🇦🇷','🇦🇸','🇦🇹','🇦🇺','🇦🇼','🇦🇽','🇦🇿','🇧🇦','🇧🇧','🇧🇩','🇧🇪','🇧🇫','🇧🇬','🇧🇭','🇧🇮','🇧🇯','🇧🇲','🇧🇳','🇧🇴','🇧🇷','🇧🇸','🇧🇹','🇧🇻','🇧🇼','🇧🇾','🇧🇿','🇨🇦','🇨🇨','🇨🇩','🇨🇫','🇨🇬','🇨🇭','🇨🇮','🇨🇰','🇨🇱','🇨🇲','🇨🇳','🇨🇴','🇨🇵','🇨🇷','🇨🇺','🇨🇻','🇨🇼','🇨🇽','🇨🇾','🇨🇿','🇩🇪','🇩🇯','🇩🇰','🇩🇲','🇩🇴','🇩🇿','🇪🇨','🇪🇪','🇪🇬','🇪🇷','🇪🇸','🇪🇹','🇪🇺','🇫🇮','🇫🇯','🇫🇲','🇫🇴','🇫🇷','🇬🇦','🇬🇧','🇬🇩','🇬🇪','🇬🇬','🇬🇭','🇬🇮','🇬🇱','🇬🇲','🇬🇳','🇬🇶','🇬🇷','🇬🇹','🇬🇺','🇬🇼','🇬🇾','🇭🇰','🇭🇲','🇭🇳','🇭🇷','🇭🇹','🇭🇺','🇮🇨','🇮🇩','🇮🇪','🇮🇱','🇮🇲','🇮🇳','🇮🇴','🇮🇶','🇮🇷','🇮🇸','🇮🇹','🇯🇪','🇯🇲','🇯🇴','🇯🇵','🇰🇪','🇰🇬','🇰🇭','🇰🇮','🇰🇲','🇰🇳','🇰🇵','🇰🇷','🇰🇼','🇰🇾','🇰🇿','🇱🇦','🇱🇧','🇱🇨','🇱🇮','🇱🇰','🇱🇷','🇱🇸','🇱🇹','🇱🇺','🇱🇻','🇱🇾','🇲🇦','🇲🇨','🇲🇩','🇲🇪','🇲🇬','🇲🇭','🇲🇰','🇲🇱','🇲🇲','🇲🇳','🇲🇴','🇲🇵','🇲🇷','🇲🇸','🇲🇹','🇲🇺','🇲🇻','🇲🇼','🇲🇽','🇲🇾','🇲🇿','🇳🇦','🇳🇪','🇳🇫','🇳🇬','🇳🇮','🇳🇱','🇳🇴','🇳🇵','🇳🇷','🇳🇺','🇳🇿','🇴🇲','🇵🇦','🇵🇪','🇵🇫','🇵🇬','🇵🇭','🇵🇰','🇵🇱','🇵🇳','🇵🇷','🇵🇸','🇵🇹','🇵🇼','🇵🇾','🇶🇦','🇷🇴','🇷🇸','🇷🇺','🇷🇼','🇸🇦','🇸🇧','🇸🇨','🇸🇩','🇸🇪','🇸🇬','🇸🇭','🇸🇮','🇸🇯','🇸🇰','🇸🇱','🇸🇲','🇸🇳','🇸🇴','🇸🇷','🇸🇸','🇸🇹','🇸🇻','🇸🇽','🇸🇾','🇸🇿','🇹🇦','🇹🇨','🇹🇩','🇹🇬','🇹🇭','🇹🇯','🇹🇰','🇹🇱','🇹🇲','🇹🇳','🇹🇴','🇹🇷','🇹🇹','🇹🇻','🇹🇼','🇹🇿','🇺🇦','🇺🇬','🇺🇲','🇺🇳','🇺🇸','🇺🇾','🇺🇿','🇻🇦','🇻🇨','🇻🇪','🇻🇬','🇻🇮','🇻🇳','🇻🇺','🇼🇸','🇾🇪','🇿🇦','🇿🇲','🇿🇼',]);
final Map<String, String> foods = Map.fromIterables([':grapes:',':melon:',':watermelon:',':tangerine:',':lemon:',':banana:',':pineapple:',':mango:',':apple:',':green_apple:',':pear:',':peach:',':cherries:',':strawberry:',':kiwi:',':tomato:',':coconut:',':avocado:',':eggplant:',':potato:',':carrot:',':corn:',':cucumber:',':leafy_green:',':broccoli:',':mushroom:',':peanuts:',':chestnut:',':bread:',':croissant:',':french_bread:',':pretzel:',':bagel:',':pancakes:',':cheese:',':meat_on_bone:',':poultry_leg:',':cut_of_meat:',':bacon:',':hamburger:',':fries:',':pizza:',':hotdog:',':sandwich:',':taco:',':burrito:',':stuffed_flatbread:',':cooking:',':shallow_pan_of_food:',':stew:',':bowl_with_spoon:',':salad:',':popcorn:',':salt:',':canned_food:',':bento:',':rice_cracker:',':rice_ball:',':rice:',':curry:',':ramen:',':spaghetti:',':sweet_potato:',':oden:',':sushi:',':fried_shrimp:',':fish_cake:',':moon_cake:',':dango:',':dumpling:',':fortune_cookie:',':takeout_box:',':icecream:',':shaved_ice:',':ice_cream:',':doughnut:',':cookie:',':birthday:',':cake:',':cupcake:',':pie:',':chocolate_bar:',':candy:',':lollipop:',':custard:',':honey_pot:',':baby_bottle:',':milk:',':coffee:',':tea:',':sake:',':champagne:',':wine_glass:',':cocktail:',':tropical_drink:',':beer:',':beers:',':champagne_glass:',':tumbler_glass:',':cup_with_straw:',':chopsticks:',':fork_and_knife:',':spoon:',], ['🍇','🍈','🍉','🍊','🍋','🍌','🍍','🥭','🍎','🍏','🍐','🍑','🍒','🍓','🥝','🍅','🥥','🥑','🍆','🥔','🥕','🌽','🥒','🥬','🥦','🍄','🥜','🌰','🍞','🥐','🥖','🥨','🥯','🥞','🧀','🍖','🍗','🥩','🥓','🍔','🍟','🍕','🌭','🥪','🌮','🌯','🥙','🍳','🥘','🍲','🥣','🥗','🍿','🧂','🥫','🍱','🍘','🍙','🍚','🍛','🍜','🍝','🍠','🍢','🍣','🍤','🍥','🥮','🍡','🥟','🥠','🥡','🍦','🍧','🍨','🍩','🍪','🎂','🍰','🧁','🥧','🍫','🍬','🍭','🍮','🍯','🍼','🥛','☕','🍵','🍶','🍾','🍷','🍸','🍹','🍺','🍻','🥂','🥃','🥤','🥢','🍴','🥄',]);
final Map<String, String> objects = Map.fromIterables([':love_letter:',':bomb:',':bath:',':sleeping_accommodation:',':knife:',':amphora:',':compass:',':bricks:',':barber:',':luggage:',':hourglass:',':hourglass_flowing_sand:',':watch:',':alarm_clock:',':firecracker:',':balloon:',':tada:',':confetti_ball:',':dolls:',':flags:',':wind_chime:',':red_envelope:',':ribbon:',':gift:',':crystal_ball:',':nazar_amulet:',':teddy_bear:',':thread:',':yarn:',':prayer_beads:',':gem:',':postal_horn:',':radio:',':iphone:',':calling:',':telephone_receiver:',':pager:',':fax:',':battery:',':electric_plug:',':computer:',':minidisc:',':floppy_disk:',':cd:',':dvd:',':abacus:',':movie_camera:',':tv:',':camera:',':camera_with_flash:',':video_camera:',':vhs:',':mag:',':mag_right:',':bulb:',':flashlight:',':izakaya_lantern:',':notebook_with_decorative_cover:',':closed_book:',':book:',':green_book:',':blue_book:',':orange_book:',':books:',':notebook:',':page_with_curl:',':scroll:',':page_facing_up:',':newspaper:',':bookmark_tabs:',':bookmark:',':moneybag:',':yen:',':dollar:',':euro:',':pound:',':money_with_wings:',':credit_card:',':receipt:',':e-mail:',':incoming_envelope:',':envelope_with_arrow:',':outbox_tray:',':inbox_tray:',':package:',':mailbox:',':mailbox_closed:',':mailbox_with_mail:',':mailbox_with_no_mail:',':postbox:',':pencil:',':file_folder:',':open_file_folder:',':date:',':calendar:',':card_index:',':chart_with_upwards_trend:',':chart_with_downwards_trend:',':bar_chart:',':clipboard:',':pushpin:',':round_pushpin:',':paperclip:',':straight_ruler:',':triangular_ruler:',':lock:',':unlock:',':lock_with_ink_pen:',':closed_lock_with_key:',':key:',':hammer:',':gun:',':wrench:',':nut_and_bolt:',':link:',':toolbox:',':magnet:',':test_tube:',':petri_dish:',':dna:',':microscope:',':telescope:',':satellite:',':syringe:',':pill:',':door:',':toilet:',':shower:',':bathtub:',':squeeze_bottle:',':safety_pin:',':broom:',':basket:',':roll_of_paper:',':soap:',':sponge:',':fire_extinguisher:',':smoking:',':moyai:',':potable_water:',], ['💌','💣','🛀','🛌','🔪','🏺','🧭','🧱','💈','🧳','⌛','⏳','⌚','⏰','🧨','🎈','🎉','🎊','🎎','🎏','🎐','🧧','🎀','🎁','🔮','🧿','🧸','🧵','🧶','📿','💎','📯','📻','📱','📲','📞','📟','📠','🔋','🔌','💻','💽','💾','💿','📀','🧮','🎥','📺','📷','📸','📹','📼','🔍','🔎','💡','🔦','🏮','📔','📕','📖','📗','📘','📙','📚','📓','📃','📜','📄','📰','📑','🔖','💰','💴','💵','💶','💷','💸','💳','🧾','📧','📨','📩','📤','📥','📦','📫','📪','📬','📭','📮','📝','📁','📂','📅','📆','📇','📈','📉','📊','📋','📌','📍','📎','📏','📐','🔒','🔓','🔏','🔐','🔑','🔨','🔫','🔧','🔩','🔗','🧰','🧲','🧪','🧫','🧬','🔬','🔭','📡','💉','💊','🚪','🚽','🚿','🛁','🧴','🧷','🧹','🧺','🧻','🧼','🧽','🧯','🚬','🗿','🚰',]);
final Map<String, String> symbols = Map.fromIterables([':cupid:',':gift_heart:',':sparkling_heart:',':heartpulse:',':heartbeat:',':revolving_hearts:',':two_hearts:',':heart_decoration:',':broken_heart:',':orange_heart:',':yellow_heart:',':green_heart:',':blue_heart:',':purple_heart:',':black_heart:',':100:',':anger:',':speech_balloon:',':eye_in_speech_bubble:',':thought_balloon:',':zzz:',':white_flower:',':barber:',':octagonal_sign:',':clock12:',':clock1230:',':clock1:',':clock130:',':clock2:',':clock230:',':clock3:',':clock330:',':clock4:',':clock430:',':clock5:',':clock530:',':clock6:',':clock630:',':clock7:',':clock730:',':clock8:',':clock830:',':clock9:',':clock930:',':clock10:',':clock1030:',':clock11:',':clock1130:',':cyclone:',':black_joker:',':mahjong:',':flower_playing_cards:',':mute:',':speaker:',':sound:',':loud_sound:',':loudspeaker:',':mega:',':postal_horn:',':bell:',':no_bell:',':musical_note:',':notes:',':atm:',':put_litter_in_its_place:',':potable_water:',':wheelchair:',':mens:',':womens:',':restroom:',':baby_symbol:',':wc:',':children_crossing:',':no_entry:',':no_entry_sign:',':no_bicycles:',':no_smoking:',':do_not_litter:',':non-potable_water:',':no_pedestrians:',':underage:',':arrows_clockwise:',':arrows_counterclockwise:',':back:',':end:',':on:',':soon:',':top:',':place_of_worship:',':menorah:',':six_pointed_star:',':aries:',':taurus:',':gemini:',':cancer:',':leo:',':virgo:',':libra:',':scorpius:',':sagittarius:',':capricorn:',':aquarius:',':pisces:',':ophiuchus:',':twisted_rightwards_arrows:',':repeat:',':repeat_one:',':fast_forward:',':rewind:',':arrow_up_small:',':arrow_double_up:',':arrow_down_small:',':arrow_double_down:',':cinema:',':low_brightness:',':high_brightness:',':signal_strength:',':vibration_mode:',':mobile_phone_off:',':trident:',':name_badge:',':beginner:',':o:',':white_check_mark:',':x:',':negative_squared_cross_mark:',':heavy_plus_sign:',':heavy_minus_sign:',':heavy_division_sign:',':curly_loop:',':loop:',':question:',':grey_question:',':grey_exclamation:',':exclamation:',':hash:',':zero:',':one:',':two:',':three:',':four:',':five:',':six:',':seven:',':eight:',':nine:',':keycap_ten:',':capital_abcd:',':abcd:',':1234:',':symbols:',':abc:',':ab:',':cl:',':cool:',':free:',':id:',':new:',':ng:',':ok:',':sos:',':up:',':vs:',':koko:',':u6709:',':u6307:',':ideograph_advantage:',':u5272:',':u7121:',':u7981:',':accept:',':u7533:',':u5408:',':u7a7a:',':u55b6:',':u6e80:',':red_circle:',':blue_circle:',':black_circle:',':white_circle:',':black_large_square:',':white_large_square:',':black_medium_small_square:',':white_medium_small_square:',':large_orange_diamond:',':large_blue_diamond:',':small_orange_diamond:',':small_blue_diamond:',':small_red_triangle:',':small_red_triangle_down:',':diamond_shape_with_a_dot_inside:',':white_square_button:',':black_square_button:',], ['💘','💝','💖','💗','💓','💞','💕','💟','💔','🧡','💛','💚','💙','💜','🖤','💯','💢','💬','👁️‍🗨️','💭','💤','💮','💈','🛑','🕛','🕧','🕐','🕜','🕑','🕝','🕒','🕞','🕓','🕟','🕔','🕠','🕕','🕡','🕖','🕢','🕗','🕣','🕘','🕤','🕙','🕥','🕚','🕦','🌀','🃏','🀄','🎴','🔇','🔈','🔉','🔊','📢','📣','📯','🔔','🔕','🎵','🎶','🏧','🚮','🚰','♿','🚹','🚺','🚻','🚼','🚾','🚸','⛔','🚫','🚳','🚭','🚯','🚱','🚷','🔞','🔃','🔄','🔙','🔚','🔛','🔜','🔝','🛐','🕎','🔯','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓','⛎','🔀','🔁','🔂','⏩','⏪','🔼','⏫','🔽','⏬','🎦','🔅','🔆','📶','📳','📴','🔱','📛','🔰','⭕','✅','❌','❎','➕','➖','➗','➰','➿','❓','❔','❕','❗','#️⃣','0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣','🔟','🔠','🔡','🔢','🔣','🔤','🆎','🆑','🆒','🆓','🆔','🆕','🆖','🆗','🆘','🆙','🆚','🈁','🈶','🈯','🉐','🈹','🈚','🈲','🉑','🈸','🈴','🈳','🈺','🈵','🔴','🔵','⚫','⚪','⬛','⬜','◾','◽','🔶','🔷','🔸','🔹','🔺','🔻','💠','🔳','🔲',]);
final Map<String, String> travel = Map.fromIterables([':person_rowing_boat:',':japan:',':volcano:',':mount_fuji:',':house:',':house_with_garden:',':office:',':post_office:',':european_post_office:',':hospital:',':bank:',':hotel:',':love_hotel:',':convenience_store:',':school:',':department_store:',':factory:',':japanese_castle:',':european_castle:',':wedding:',':tokyo_tower:',':statue_of_liberty:',':church:',':mosque:',':synagogue:',':kaaba:',':fountain:',':tent:',':foggy:',':night_with_stars:',':sunrise_over_mountains:',':sunrise:',':city_dusk:',':city_sunset:',':bridge_at_night:',':carousel_horse:',':ferris_wheel:',':roller_coaster:',':steam_locomotive:',':railway_car:',':bullettrain_side:',':bullettrain_front:',':train2:',':metro:',':light_rail:',':station:',':tram:',':monorail:',':mountain_railway:',':train:',':bus:',':oncoming_bus:',':trolleybus:',':minibus:',':ambulance:',':fire_engine:',':police_car:',':oncoming_police_car:',':taxi:',':oncoming_taxi:',':red_car:',':oncoming_automobile:',':truck:',':articulated_lorry:',':tractor:',':motor_scooter:',':bike:',':scooter:',':busstop:',':fuelpump:',':rotating_light:',':traffic_light:',':vertical_traffic_light:',':construction:',':anchor:',':sailboat:',':speedboat:',':ship:',':airplane_departure:',':airplane_arriving:',':seat:',':helicopter:',':suspension_railway:',':mountain_cableway:',':aerial_tramway:',':rocket:',':flying_saucer:',':stars:',':milky_way:',':fireworks:',':sparkler:',':rice_scene:',':yen:',':dollar:',':euro:',':pound:',':moyai:',':passport_control:',':customs:',':baggage_claim:',':left_luggage:',], ['🚣','🗾','🌋','🗻','🏠','🏡','🏢','🏣','🏤','🏥','🏦','🏨','🏩','🏪','🏫','🏬','🏭','🏯','🏰','💒','🗼','🗽','⛪','🕌','🕍','🕋','⛲','⛺','🌁','🌃','🌄','🌅','🌆','🌇','🌉','🎠','🎡','🎢','🚂','🚃','🚄','🚅','🚆','🚇','🚈','🚉','🚊','🚝','🚞','🚋','🚌','🚍','🚎','🚐','🚑','🚒','🚓','🚔','🚕','🚖','🚗','🚘','🚚','🚛','🚜','🛵','🚲','🛴','🚏','⛽','🚨','🚥','🚦','🚧','⚓','⛵','🚤','🚢','🛫','🛬','💺','🚁','🚟','🚠','🚡','🚀','🛸','🌠','🌌','🎆','🎇','🎑','💴','💵','💶','💷','🗿','🛂','🛃','🛄','🛅',]);