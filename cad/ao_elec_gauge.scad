// Flat gauge for AO-02 electrical boss shape verification
// Parent: regular pentagon, circumdiameter ao_elec_od
// Each of 5 vertices truncated to a 3 mm flat → decagon (10 sides)
// Print and try the hole over the real sensor boss.

ao_elec_od   = 23.0;         // parent pentagon circumscribed Ø (was 20 → 21 → 22 → 23)
corner_flat  = 3.0;          // straight at each former vertex
gauge_t      = 1.5;          // thin plate for quick print
outer_d      = 32.0;
fn           = 64;

R = ao_elec_od / 2;

// Distance along each edge from vertex to truncation point
function trunc_s(flat) = flat / (2 * sin(54));

function pent_verts(r) =
    [for (i = [0:4]) [r * cos(i * 72), r * sin(i * 72)]];

// 10 vertices: for each pentagon vertex, two points on adjacent edges
function trunc_pent_verts(r, flat = 3) =
    let(s = trunc_s(flat), pv = pent_verts(r))
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

module ao_elec_profile() {
    polygon(trunc_pent_verts(R, corner_flat));
}

// Female ring: hole to slip over sensor boss
module gauge_female() {
    difference() {
        cylinder(h = gauge_t, d = outer_d, $fn = fn);
        translate([0, 0, -0.05])
            linear_extrude(height = gauge_t + 0.1)
                ao_elec_profile();
    }
}

gauge_female();
