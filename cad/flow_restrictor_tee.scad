// Sample tee for AO-02 — lean printable T.
// Tube OD 25; M16 boss OD 20; orifices open into tube bore.
//
// M16x1 FEMALE tuned for FDM (printed hole runs small → enlarge):
//   ISO M16x1: major 16 / pitch 15.35 / minor ~14.92
//   Print: minor ~15.6, major ~16.8 so commercial AO-02 male starts easily.
//
// Print: cad/stl/tee.stl

tube_od   = 25.0;
tube_len  = 40.0;
wall      = 2.2;
in_id     = tube_od - 2 * wall;  // 20.6
out_id    = in_id - 3.0;         // 17.6 (was −1.5 → 19.1)

stem_od   = 20.0;
stem_h    = 8.0;                 // was 12 — AO-02 male thread < 6 mm

plate_t   = 2.0;
orifice_d = 2.5;
orifice_r = 3.5;

// Narrow bore starts past +X orifice so hole opens into wide ID
narrow_x0 = 6.5;                 // was −2; orifice at +orifice_r ≈ 3.5
taper_len = 4.0;

// Raised flow arrow on tube crown (points toward narrow / +X outlet)
arrow_h      = 0.9;
arrow_shaft_l = 12.0;
arrow_shaft_w = 2.2;
arrow_head_l  = 5.5;
arrow_head_w  = 6.0;

tube_z    = in_id / 2;

// —— M16x1 internal, FDM-compensated ——
m16_pitch       = 1.0;
m16_minor_d     = 15.6;
m16_major_d     = 16.8;
m16_engage      = 5.5;           // match AO-02 stub (~6 mm, leave a little short)

fn  = 72;
eps = 0.08;

module m16_female(h) {
    // Straight minor bore + shallow major grooves (printable internal thread)
    r_min = m16_minor_d / 2;
    r_maj = m16_major_d / 2;
    union() {
        cylinder(h = h, r = r_min, $fn = fn);
        for (z = [0 : m16_pitch : h - 0.2])
            translate([0, 0, z + 0.15])
                cylinder(h = 0.40, r = r_maj, $fn = fn);
    }
}

// 2D arrow in XY, tip at +X (flow toward narrow outlet)
module flow_arrow_2d() {
    shaft_x0 = -(arrow_shaft_l + arrow_head_l) / 2;
    head_x0  = shaft_x0 + arrow_shaft_l;
    tip_x    = head_x0 + arrow_head_l;
    polygon([
        [shaft_x0, -arrow_shaft_w / 2],
        [head_x0,  -arrow_shaft_w / 2],
        [head_x0,  -arrow_head_w / 2],
        [tip_x,     0],
        [head_x0,   arrow_head_w / 2],
        [head_x0,   arrow_shaft_w / 2],
        [shaft_x0,  arrow_shaft_w / 2]
    ]);
}

module flow_arrow() {
    // Sit on tube crown; slight sink so it merges with the OD
    translate([0, 0, tube_z + tube_od / 2 - 0.15])
        linear_extrude(height = arrow_h + 0.15)
            flow_arrow_2d();
}

module tee() {
    difference() {
        union() {
            translate([0, 0, tube_z])
                rotate([0, 90, 0])
                    translate([0, 0, -tube_len / 2])
                        cylinder(h = tube_len, d = tube_od, $fn = fn);

            translate([0, 0, -stem_h])
                cylinder(h = stem_h + plate_t, d = stem_od, $fn = fn);

            flow_arrow();
        }

        // Horizontal gas path: wide inlet (−X) → narrow outlet (+X)
        // Transition after +X orifice so restrictor opens into wide bore
        translate([0, 0, tube_z]) {
            translate([-tube_len / 2 - eps, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h = narrow_x0 + tube_len / 2 + 1, d = in_id, $fn = fn);
            translate([narrow_x0, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h = tube_len / 2 - narrow_x0 + eps, d = out_id, $fn = fn);
            translate([narrow_x0 - taper_len, 0, 0])
                rotate([0, 90, 0])
                    cylinder(h = taper_len, d1 = in_id, d2 = out_id, $fn = fn);
        }

        // M16 female — ends at plate underside
        thread_h = min(m16_engage, stem_h - plate_t);
        translate([0, 0, -stem_h - eps])
            m16_female(thread_h + eps);

        // Smooth lead-in (helps FDM start on AO-02 male)
        translate([0, 0, -stem_h])
            cylinder(h = 2.5, d1 = m16_major_d + 0.4, d2 = m16_minor_d, $fn = fn);

        // Clear bore from thread top to plate
        translate([0, 0, -stem_h + thread_h - eps])
            cylinder(h = stem_h - plate_t - thread_h + 2 * eps,
                     d = m16_minor_d, $fn = fn);

        // Restrictor holes Ø2.5 → tube (within ~Ø10 face)
        for (a = [0, 120, 240]) {
            rotate([0, 0, a])
                translate([orifice_r, 0, -plate_t - eps])
                    cylinder(h = plate_t + 4, d = orifice_d, $fn = 24);
        }
        translate([0, 0, -plate_t - eps])
            cylinder(h = plate_t + 4, d = orifice_d, $fn = 24);
    }
}

tee();
