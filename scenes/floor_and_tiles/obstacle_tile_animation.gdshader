shader_type spatial;

uniform float speed = 1.0;
uniform float stripe_width = 0.1;
uniform vec4 color1: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color2: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float pattern_scale = 5.0;
uniform float emission_strength = 1.0;

void fragment() {
    // Center the UV coordinates
    vec2 centered_uv = UV - 0.5;

    // Calculate the angle and distance from the center
    float angle = atan(centered_uv.y, centered_uv.x);
    float distance = length(centered_uv);

    // Create a rotating effect
    float rotated_angle = angle + TIME * speed;

    // Map the angle to a linear space for the stripe pattern
    float linear_position = (rotated_angle / (2.0 * 3.14159)) * pattern_scale;

    // Create the stripe pattern
    float stripe = mod(linear_position, stripe_width * 2.0);
    float is_stripe = step(stripe, stripe_width);

    // Fade the pattern towards the center
    float fade = smoothstep(0.0, 0.5, distance);

    // Mix colors based on stripe and fade
    vec4 pattern_color = mix(color2, color1, is_stripe);
    vec4 final_color = mix(COLOR, pattern_color, fade);

    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;

    // Add emission
    EMISSION = final_color.rgb * emission_strength * fade;
}