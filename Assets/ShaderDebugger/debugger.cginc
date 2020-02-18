/* note: remember to add "#pragma target 4.5"! */


#define _DEBUG_ROOT           1
#define _DEBUG_SET_COLOR      2
#define _DEBUG_SET_POS        3
#define _DEBUG_RESET_POS      4
#define _DEBUG_CHANGE_POS     5
#define _DEBUG_SPHERE        10
#define _DEBUG_VALUE1        11
#define _DEBUG_VALUE2        12
#define _DEBUG_VALUE3        13
#define _DEBUG_VALUE4        14
#define _DEBUG_COLOR_PATCH   15
#define _DEBUG_VECTOR        16
#define _DEBUG_DIRECTION     17
#define _DEBUG_CUBE          18
#define _DEBUG_SCREEN_DISC   19


struct _DebugStruct
{
    uint next;
    uint kind;
    float4 v;
};

RWStructuredBuffer<_DebugStruct> _internal_debug_buffer : register(u7);

void _DbgEmit(uint root, uint kind, float4 v)
{
    uint new_entry = _internal_debug_buffer.IncrementCounter() + 1;
    uint current_tail = _internal_debug_buffer[root].next;
    _internal_debug_buffer[root].next = new_entry;

    _DebugStruct s;
    s.next = current_tail;
    s.kind = kind;
    s.v = v;
    _internal_debug_buffer[new_entry] = s;
}

uint _DbgEmitStart(float4 v)
{
    _DebugStruct s;
    uint root = _internal_debug_buffer.IncrementCounter() + 1;
    s.next = root;
    s.kind = _DEBUG_ROOT;
    s.v = v;
    _internal_debug_buffer[root] = s;
    return root;
}


uint DebugVertexW4(float4 world_position) { return _DbgEmitStart(float4(world_position.xyz / world_position.w, 0)); }
uint DebugVertexO4(float4 obj_position) { return DebugVertexW4(mul(unity_ObjectToWorld, obj_position)); }
uint DebugFragment(float4 sv_position) { return _DbgEmitStart(sv_position); }

void DbgSetColor(uint root, float4 color) { _DbgEmit(root, _DEBUG_SET_COLOR, color); }

void DbgChangePosToO4(uint root, float4 obj_position) { float4 wp = mul(unity_ObjectToWorld, obj_position); _DbgEmit(root, _DEBUG_SET_POS, float4(wp.xyz / wp.w, 55)); }
void DbgChangePosByO3(uint root, float3 obj_vector) { _DbgEmit(root, _DEBUG_CHANGE_POS, float4(mul((float3x3)unity_ObjectToWorld, obj_vector), 55)); }
void DbgChangePosToW4(uint root, float4 world_position) { _DbgEmit(root, _DEBUG_SET_POS, float4(world_position.xyz / world_position.w, 66)); }
void DbgChangePosByW3(uint root, float3 world_vector) { _DbgEmit(root, _DEBUG_CHANGE_POS, float4(world_vector, 66)); }
void DbgResetPos(uint root) { _DbgEmit(root, _DEBUG_RESET_POS, float4(0, 0, 0, 0)); }
//void DbgMoveC4(uint root, float4 clip_position) { _DbgEmit(root, _DEBUG_SET_POS, float4(clip_position.xyz / clip_position.w, 77)); }
//void DbgMoveV4(uint root, float4 sv_position) { _DbgEmit(root, _DEBUG_SET_POS, float4(sv_position.xyz / sv_position.w, 88)); }
//void DbgMoveO3(uint root, float3 obj_position) { float4 wp = mul(unity_ObjectToWorld, float4(obj_position, 1)); _DbgEmit(root, _DEBUG_SET_POS, float4(wp.xyz / wp.w, 55)); }
//void DbgMoveW3(uint root, float3 world_position) { _DbgEmit(root, _DEBUG_SET_POS, float4(world_position, 66)); }

//void DbgSphereO1(uint root, float obj_radius) { ... }
void DbgSphereW1(uint root, float world_radius) { _DbgEmit(root, _DEBUG_SPHERE, float4(world_radius, 0, 0, 66)); }

void DbgValue1(uint root, float value) { _DbgEmit(root, _DEBUG_VALUE1, float4(value, 0, 0, 0)); }
void DbgValue2(uint root, float2 value) { _DbgEmit(root, _DEBUG_VALUE2, float4(value, 0, 0)); }
void DbgValue3(uint root, float3 value) { _DbgEmit(root, _DEBUG_VALUE3, float4(value, 0)); }
void DbgValue4(uint root, float4 value) { _DbgEmit(root, _DEBUG_VALUE4, value); }

void DbgDisc(uint root, float size_multiplier) { _DbgEmit(root, _DEBUG_SCREEN_DISC, float4(size_multiplier, 0, 0, 0)); }
//void DbgDiscW3(uint root, float3 world_normal, float world_radius) { _DbgEmit(root, _DEBUG_DISC, float4(world_normal, world_radius)); }

void DbgVectorO3(uint root, float3 obj_vector) { _DbgEmit(root, _DEBUG_VECTOR, float4(mul((float3x3)unity_ObjectToWorld, obj_vector), 55)); }
void DbgVectorW3(uint root, float3 world_vector) { _DbgEmit(root, _DEBUG_VECTOR, float4(world_vector, 66)); }

//void DbgDirectionO3(uint root, float3 obj_direction) { _DbgEmit(root, _DEBUG_DIRECTION, float4(mul((float3x3)unity_ObjectToWorld, obj_direction), 55)); }
//void DbgDirectionW3(uint root, float3 world_direction) { _DbgEmit(root, _DEBUG_DIRECTION, float4(world_direction, 66)); }

//void DbgCubeSizeO3(uint root, float3 obj_size) { ... }
//void DbgCubeSizeW3(uint root, float3 world_size) { _DbgEmit(root, _DEBUG_CUBE, float4(world_size, 66)); }
//void DbgCubeExtentsO3(uint root, float3 obj_extents) { ... }
//void DbgCubeExtentsW3(uint root, float3 world_extents) { DbgCubeSizeW3(root, world_extents * 2); }
