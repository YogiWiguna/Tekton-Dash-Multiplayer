shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec2 scroll_speed = vec2(1.0, 1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D orm_texture : hint_default_white;
uniform sampler2D emission_texture : source_color;

uniform float emission_energy : hint_range(0.0, 16.0) = 1.0;
uniform vec4 modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float normal_fade : hint_range(0.0, 0.999) = 0.0;
uniform float albedo_mix : hint_range(0.0, 1.0) = 1.0;

// Emission control uniforms
uniform vec3 emission_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float emission_alpha_influence : hint_range(-1.0, 1.0) = 0.0;
uniform float emission_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float emission_softness : hint_range(0.0, 1.0) = 0.1;

// Projection control uniforms
uniform bool project_on_x = true;
uniform bool project_on_y = true;
uniform bool project_on_z = true;
uniform float projection_angle_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float projection_smoothness : hint_range(0.0, 1.0) = 0.1;

float get_luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

float get_projection_mask(vec3 normal) {
    // Convert normal to absolute values for comparison
    vec3 abs_normal = abs(normal);
    
    // Initialize mask
    float mask = 0.0;
    
    // Check each axis projection
    if (project_on_x) {
        float x_contrib = smoothstep(
            projection_angle_threshold - projection_smoothness,
            projection_angle_threshold + projection_smoothness,
            abs_normal.x
        );
        mask = max(mask, x_contrib);
    }
    
    if (project_on_y) {
        float y_contrib = smoothstep(
            projection_angle_threshold - projection_smoothness,
            projection_angle_threshold + projection_smoothness,
            abs_normal.y
        );
        mask = max(mask, y_contrib);
    }
    
    if (project_on_z) {
        float z_contrib = smoothstep(
            projection_angle_threshold - projection_smoothness,
            projection_angle_threshold + projection_smoothness,
            abs_normal.z
        );
        mask = max(mask, z_contrib);
    }
    
    // If no projection is enabled, show on all surfaces
    if (!project_on_x && !project_on_y && !project_on_z) {
        mask = 1.0;
    }
    
    return mask;
}

void fragment() {
    // Get the surface normal
    vec3 surface_normal = NORMAL;
    
    // Calculate projection mask
    float proj_mask = get_projection_mask(surface_normal);
    
    // If projection mask is 0, discard the fragment
    if (proj_mask <= 0.0) {
        discard;
    }
    
    // Calculate scaled and offset UVs
    vec2 scaled_uv = (UV - 0.5) * uv_scale + 0.5 + uv_offset;
    
    // Calculate UV offset based on time
    vec2 time_offset = scroll_speed * TIME;
    vec2 moving_uv = scaled_uv + time_offset;
    
    // Sample textures with moving UVs
    vec4 albedo = texture(albedo_texture, moving_uv);
    vec4 emission_tex = texture(emission_texture, moving_uv);
    vec4 orm = texture(orm_texture, moving_uv);
    vec3 normal_map = texture(normal_texture, moving_uv).rgb;
    
    // Calculate emission luminance
    float emission_lum = get_luminance(emission_tex.rgb);
    
    // Apply threshold with softness
    float emission_factor = smoothstep(
        emission_threshold - emission_softness,
        emission_threshold + emission_softness,
        emission_lum
    );
    
    // Calculate alpha influence from emission
    float emission_alpha_mod = mix(1.0, emission_factor, abs(emission_alpha_influence));
    if (emission_alpha_influence < 0.0) {
        emission_alpha_mod = 1.0 - emission_alpha_mod;
    }
    
    // Apply normal fade
    float fade = 1.0 - normal_fade;
    
    // Set outputs with projection mask
    ALBEDO = albedo.rgb * modulate.rgb;
    ALPHA = albedo.a * modulate.a * fade * emission_alpha_mod * proj_mask;
    EMISSION = emission_color * emission_factor * emission_energy * proj_mask;
    
    // Material properties
    ROUGHNESS = orm.g;
    METALLIC = orm.r;
    AO = orm.b;
    NORMAL = normal_map;
}