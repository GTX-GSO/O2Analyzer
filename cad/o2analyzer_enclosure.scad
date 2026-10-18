// O2Analyzer enclosure
// - Display: inner-wall flat + U-rail (bottom-load, top stop) + upper through-window
// - AO-02 elec seat: truncated pentagon (5×3 mm flats → decagon), gauge-validated Ø23
// - Body split: open-bottom lower bay + upper (elec seat + sensor tube), friction sleeve
// - Lower: separable bottom_cap (Type-C outboard of OLED) + ESP slots + PCB top stop
// - Top: friction press-fit disc into sensor cavity, center Ø20 (M16 exposed)
// - Shell Ø34; bay and sensor cavity same ID Ø30; ledge_z = 32
// - Radial +X stack (out→in): wall → screen U-rail → Type-C → ESP PCB (more central)

part = "none"; // ["none","preview","body","body_lower","body_upper","top_cap","bottom_cap","all_print"]

/* [AO-02] */
ao_od         = 29.2;
ao_elec_od    = 23.0;        // parent pentagon circum-Ø (gauge-validated)
ao_elec_clear = 0.0;         // extra diametral slack on top of validated hole
ao_elec_flat  = 3.0;         // 3 mm flat at each former pentagon vertex → decagon
ao_h_body         = 25.0;
sensor_top_clear  = 4.5;     // cavity above AO-02 shoulder for top_cap (was 4.0; +0.5 so cap seats)
ao_clear          = 0.32;    // retained for reference
sensor_narrow     = 0.0;     // diametral: 0 → sensor cavity = bay Ø30

/* [Boards] — PCB outline; Type-C shell ~1 mm past PCB edge (floor hole only) */
sm_l = 24.5;                 // ESP length along Z (USB → far end)
sm_w = 20.5;                 // ESP narrow end along Y
ads_l = 25.3;                // ADS length along Z (vertical)
ads_w = 9.5;                 // ADS width along Y
ads_t = 1.6;                 // ADS PCB thickness along X
esp_t = 1.6;                 // ESP PCB thickness (OLED face → back)
board_clear = 0.3;
esp_inset   = 0.7;           // pull face inward for chord clearance at ID

/* [Shell] */
wall      = 2.0;
outer_d   = 34.0;
bay_inner = 26.0;            // floor inner → wire zone (sm_l 24.5 + stop 1.5)
wire_h    = 4.0;             // soldered-lead service loop
ledge_t   = 1.2;
fn        = 96;

/* [Body join] — friction sleeve at ledge (lower male → upper counterbore) */
join_male_h    = 5.0;        // male height
join_female_h  = 5.0;        // upper counterbore
join_interfere = 0.20;       // female bore = male nominal OD − this (unchanged)
join_male_extra = 0.15;      // diametral thicken of male OD only (PETG grip; reprint lower)
join_wall      = 1.0;
join_lead      = 0.8;        // male tip chamfer (within join_male_h, not above)

/* [Display window] — +X inner wall, z from assembled outer bottom */
disp_w      = 13.0;
disp_h      = 11.0;
disp_z0     = 12.0;          // pcb_z0 (bot_t 2) + 10
disp_glue_h = 4.0;
disp_view_h = 7.0;

/* [Display U-rail] — screen only; bottom-load; top stop */
disp_t      = 1.5;
rail_clear  = 0.2;
rail_lip    = 0.8;
rail_side   = 1.2;
rail_lip_y  = 1.5;
rail_top_t  = 1.0;           // top stop height (Z)
rail_recess = 1.5;

/* [Top friction disc] */
top_plate_t   = 2.5;         // engage band (was 2.0; more axial grip)
top_hole_d    = 20.0;
top_interfere = 0.45;        // diametral vs cavity ID

/* [Type-C floor hole] — OLED-face side (outboard); snug to shell + FDM slack */
tc_w = 9.4;                  // ~8.9 shell + clearance (was 9.2; +0.2 for fit)
tc_h = 3.7;                  // ~3.3 shell + clearance (was 3.5; +0.2 for fit)
tc_face_overlap = 0.75;      // root of shell still overlaps PCB/pads at OLED face

/* [ESP slots] — bottom-load full-height guides + PCB top hard stop */
esp_rail_z_lo = 1.0;         // above floor (clear Type-C shell)
esp_stop_h    = 1.5;         // hard stop above PCB top

/* [Display U-rail Z] — raised above Type-C shell for bottom clearance */
rail_z_lo = 6.0;             // U-rail starts this far above pcb_z0

/* [Bottom cap] — solid friction disc (Type-C on +X; align visually to display) */
bot_interfere = 0.20;        // diametral interference vs bay ID
bot_t         = 2.0;         // disc thickness = press-fit engage
bot_lead_in   = 0.8;         // body bottom entrance chamfer


inner_r     = outer_d / 2 - wall;                    // 15
sensor_r    = inner_r - sensor_narrow / 2;           // 15
ao_r        = ao_od / 2 + ao_clear;
ledge_z     = bot_t + bay_inner + wire_h;            // 32
sensor_h    = ao_h_body + sensor_top_clear;          // 29
eps         = 0.05;
disp_seat_x = inner_r;
ao_elec_r   = (ao_elec_od + ao_elec_clear) / 2;

// ESP OLED face behind U-rail, inset for ID chord clearance (target ~10.0)
esp_face_x  = disp_seat_x - rail_recess - (disp_t + rail_clear) - rail_lip - 0.3 - esp_inset;
esp_back_x  = esp_face_x - esp_t;
pcb_z0      = bot_t;                                 // PCB sits on bottom_cap floor
pcb_z1      = pcb_z0 + sm_l;
// Type-C on OLED/screen side: hole mostly outboard of face; PCB more central than tc_x
tc_x        = esp_face_x + tc_h / 2 - tc_face_overlap;

bot_disc_d  = 2 * inner_r + bot_interfere;

function ao_elec_trunc_s(flat) = flat / (2 * sin(54));

function ao_elec_pent_verts(r) =
    [for (i = [0:4]) [r * cos(i * 72), r * sin(i * 72)]];

function ao_elec_trunc_verts(r, flat) =
    let(s = ao_elec_trunc_s(flat), pv = ao_elec_pent_verts(r))
    [
        for (i = [0:4])
            let(
                v    = pv[i],
                prev = pv[(i + 4) % 5],
                next = pv[(i + 1) % 5],
                lp   = norm(prev - v),
                ln   = norm(next - v)
            )
            each [
                v + s * (prev - v) / lp,
                v + s * (next - v) / ln
            ]
    ];

module ao_elec_seat_cut(h) {
    linear_extrude(height = h)
        polygon(ao_elec_trunc_verts(ao_elec_r, ao_elec_flat));
}

module display_window_cuts() {
    assert(abs(disp_h - (disp_glue_h + disp_view_h)) < 0.01);

    intersection() {
        translate([0, -disp_w / 2, disp_z0])
            cube([disp_seat_x + eps, disp_w, disp_h]);
        difference() {
            translate([0, 0, disp_z0 - 1])
                cylinder(h = disp_h + 2, r = outer_d / 2 + 0.02, $fn = fn);
            translate([0, 0, disp_z0 - 1])
                cylinder(h = disp_h + 2, r = inner_r - 0.02, $fn = fn);
        }
    }

    translate([disp_seat_x - eps, -disp_w / 2, disp_z0 + disp_glue_h])
        cube([outer_d / 2 - disp_seat_x + 3, disp_w, disp_view_h]);
}

// L-rails at ±Y + top stop; open downward for bottom-load
module display_u_rail() {
    slot        = disp_t + rail_clear;
    rail_seat_x = disp_seat_x - rail_recess;
    x0          = rail_seat_x - slot - rail_lip;
    y_out       = disp_w / 2 + rail_side;
    y_in        = disp_w / 2;
    y_lip       = disp_w / 2 - rail_lip_y;
    // Raised above Type-C shell; still open downward for bottom-load
    rail_z0     = pcb_z0 + rail_z_lo;
    rail_z1     = disp_z0 + disp_h;
    rail_z_h    = rail_z1 - rail_z0;
    assert(rail_z_h > 0);

    module side_L(sign) {
        translate([x0, sign > 0 ? y_in : -y_out, rail_z0])
            cube([slot + rail_lip, rail_side, rail_z_h]);
        translate([x0, sign > 0 ? y_lip : -y_in, rail_z0])
            cube([rail_lip, rail_lip_y, rail_z_h]);
    }

    side_L(+1);
    side_L(-1);

    // Top stop bridges both sides across the slot
    translate([x0, -y_out, rail_z1])
        cube([slot + rail_lip, 2 * y_out, rail_top_t]);

    // Back-fill only over screen Z (not below window); keep view aperture
    difference() {
        translate([rail_seat_x, -y_out, disp_z0])
            cube([rail_recess + eps, 2 * y_out, disp_h + rail_top_t]);
        translate([rail_seat_x - eps, -disp_w / 2, disp_z0 + disp_glue_h])
            cube([rail_recess + 2 * eps, disp_w, disp_view_h]);
    }
}

module type_c_stadium(grow = 0) {
    hull() {
        translate([0, (tc_w - tc_h) / 2])
            circle(d = tc_h + 2 * grow, $fn = 32);
        translate([0, -(tc_w - tc_h) / 2])
            circle(d = tc_h + 2 * grow, $fn = 32);
    }
}

module type_c_cut(h = bot_t) {
    translate([tc_x, 0, -eps])
        linear_extrude(height = h + 2 * eps)
            type_c_stadium(0);
}

// ±Y full-height ESP slots + top hard stop; rails reach ID so they merge with shell
module esp_slots() {
    y_half = sm_w / 2 + board_clear;
    x0 = esp_back_x - board_clear;
    xd = esp_t + 2 * board_clear;
    rail_z0 = pcb_z0 + esp_rail_z_lo;
    rail_z1 = pcb_z1 + esp_stop_h;
    rail_h  = rail_z1 - rail_z0;

    intersection() {
        translate([0, 0, rail_z0 - eps])
            cylinder(h = rail_h + 2 * eps, r = inner_r + 0.2, $fn = fn);
        union() {
            // Side guides extend past ID chord → merge with wall
            for (sign = [-1, 1])
                translate([x0, sign > 0 ? y_half : -inner_r - 1, rail_z0])
                    cube([xd, sign > 0 ? inner_r + 1 - y_half : inner_r + 1 - y_half, rail_h]);
            // Top stop bar (same X span) — resists USB insertion
            translate([x0, -y_half, pcb_z1])
                cube([xd, 2 * y_half, esp_stop_h]);
        }
    }
}

module join_male() {
    od = 2 * sensor_r + 2 * join_wall + join_male_extra;
    id = 2 * sensor_r;
    assert(join_male_h > join_lead);
    difference() {
        union() {
            cylinder(h = join_male_h - join_lead, d = od, $fn = fn);
            translate([0, 0, join_male_h - join_lead])
                cylinder(h = join_lead, d1 = od, d2 = od - join_lead, $fn = fn);
        }
        translate([0, 0, -eps])
            cylinder(h = join_male_h + 2 * eps, d = id, $fn = fn);
    }
}

module body_lower() {
    union() {
        difference() {
            cylinder(h = ledge_z, d = outer_d, $fn = fn);

            // Open bay through bottom
            translate([0, 0, -eps])
                cylinder(h = ledge_z + 2 * eps, r = inner_r, $fn = fn);

            // Short lead-in for bottom_cap
            translate([0, 0, -eps])
                cylinder(h = bot_lead_in + eps, d1 = 2 * inner_r + 0.6, d2 = 2 * inner_r, $fn = fn);

            display_window_cuts();
        }
        display_u_rail();
        esp_slots();
        translate([0, 0, ledge_z])
            join_male();
    }
}

module body_upper() {
    // Female bore sized to nominal male (without join_male_extra)
    neck_od = 2 * sensor_r + 2 * join_wall;
    bore_d  = neck_od - join_interfere;
    h       = join_female_h + ledge_t + sensor_h;

    difference() {
        cylinder(h = h, d = outer_d, $fn = fn);

        translate([0, 0, -eps])
            cylinder(h = join_female_h + eps, d = bore_d, $fn = fn);

        translate([0, 0, join_female_h - eps])
            ao_elec_seat_cut(ledge_t + 2 * eps);

        translate([0, 0, join_female_h + ledge_t])
            cylinder(h = sensor_h + eps, r = sensor_r, $fn = fn);

        translate([0, 0, h - 1.4])
            cylinder(h = 1.4 + eps, d1 = 2 * sensor_r, d2 = 2 * sensor_r + 0.8, $fn = fn);

        translate([0, 0, -eps])
            cylinder(h = 1.0, d1 = bore_d + 0.6, d2 = bore_d, $fn = fn);
    }
}

module body() {
    body_lower();
    translate([0, 0, ledge_z])
        body_upper();
}

module friction_disc(seat_r, center_hole_d = 0) {
    disc_d = 2 * seat_r + top_interfere;
    difference() {
        union() {
            cylinder(h = top_plate_t, d = disc_d, $fn = fn);
            translate([0, 0, top_plate_t])
                cylinder(h = 0.8, d1 = disc_d, d2 = 2 * seat_r - 0.15, $fn = fn);
        }
        if (center_hole_d > 0)
            translate([0, 0, -eps])
                cylinder(h = top_plate_t + 0.8 + 2 * eps, d = center_hole_d, $fn = fn);
    }
}

module top_cap() {
    friction_disc(sensor_r, center_hole_d = top_hole_d);
}

// Separable bottom: solid press-fit disc (no cup ring — avoids bay feature pierce)
module bottom_cap() {
    difference() {
        cylinder(h = bot_t, d = bot_disc_d, $fn = fn);
        type_c_cut(bot_t);
    }
}

module preview_boards() {
    color([0.2, 0.7, 0.35, 0.55])
        translate([esp_back_x, -sm_w / 2, pcb_z0])
            cube([esp_t, sm_w, sm_l]);
    // ADS floats in −X bay (no cradle); preview only
    color([0.7, 0.45, 0.2, 0.55])
        translate([-11.0 - ads_t / 2, -ads_w / 2, pcb_z0])
            cube([ads_t, ads_w, ads_l]);
}

module preview() {
    shell_top = ledge_z + join_female_h + ledge_t + sensor_h;
    body();
    color([0.35, 0.35, 0.4, 0.85])
        bottom_cap();
    preview_boards();
    color([0.25, 0.55, 0.85, 0.9])
        translate([0, 0, shell_top + 0.05])
            mirror([0, 0, 1]) top_cap();
}

if (part == "body") body();
else if (part == "body_lower") body_lower();
else if (part == "body_upper") body_upper();
else if (part == "top_cap") top_cap();
else if (part == "bottom_cap") bottom_cap();
else if (part == "all_print") {
    body_lower();
    translate([outer_d + 12, 0, 0]) body_upper();
    translate([outer_d + 12, outer_d + 6, 0]) top_cap();
    translate([0, outer_d + 10, 0]) bottom_cap();
} else if (part == "preview") preview();
