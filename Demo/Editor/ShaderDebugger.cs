using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


namespace ShaderDebugger
{
    public class ShaderDebugger : EditorWindow
    {
        // Add "Shader Debugger" menu item to the Window menu
        [MenuItem("Window/Shader Debugger")]
        static void Init()
        {
            // Get existing open window or if none, make a new one
            ShaderDebugger window = GetWindow<ShaderDebugger>();
            window.titleContent = new GUIContent("Shader Debug");
            window.autoRepaintOnSceneChange = true;
            window.Show();
        }

        public static GUILayoutOption GL_EXPAND_WIDTH = GUILayout.ExpandWidth(true);
        public static GUILayoutOption GL_EXPAND_HEIGHT = GUILayout.ExpandHeight(true);

        Vector2 scroll_position = Vector2.zero;


        void OnGUI()
        {
            // Make the window scrollable
            scroll_position = EditorGUILayout.BeginScrollView(scroll_position, GL_EXPAND_WIDTH, GL_EXPAND_HEIGHT);

            GUILayout.BeginVertical();
            GUILayout.Space(10);

            freeze_view = EditorGUILayout.Toggle("Freeze view", freeze_view);

            if (!freeze_view)
            {
                buffer_length = EditorGUILayout.IntField("Max number of entries", buffer_length);
                display_count = EditorGUILayout.IntField("Num pixels to show", display_count);
                if (GUILayout.Button("Refresh view"))
                    most_recent_load = -1;
            }

            GUILayout.Space(10);

            var scene_view = SceneView.lastActiveSceneView;

            if (scene_view == null)
            {
                EditorGUILayout.HelpBox("No active scene view", MessageType.Error);
            }
            else if (freeze_view)
            {
                EditorGUILayout.HelpBox("The debug information displayed on screen is frozen", MessageType.Info);
            }
            else
            {
                int rec_entries = buffer == null ? -1 : 0;
                if (buffer != null && buffer.count > 0)
                {
                    buffer.GetData(debug_array, 0, 0, 1);
                    rec_entries = (int)debug_array[0].next;
                }
                EditorGUILayout.LabelField("Recorded entries", rec_entries >= 0 ? rec_entries.ToString() : "Loading...");
                if (rec_entries > buffer_length)
                    EditorGUILayout.HelpBox("Max number of entries is too small, increase it", MessageType.Error);

                if (rec_entries == 0)
                {
                    EditorGUILayout.HelpBox("No shader including 'debugging.cginc' found, or object is not drawn." +
                        "\n\nTo debug a shader, you must first call DebugFrament() inside the fragment shader and then call the " +
                        "DbgXxx() functions to record what you are interested in seeing.", MessageType.Warning);
                }
            }

            GUILayout.Space(10);
            GUILayout.EndVertical();

            EditorGUILayout.EndScrollView();
            ticks = 5;
        }

        int ticks;

        private void OnInspectorUpdate()
        {
            if (--ticks < 0)
            {
                ticks = 20;
                Repaint();
            }
        }

        /******************************************************************/


        int buffer_length = 4000000;
        int display_count = 80;
        bool freeze_view = false;

        ComputeBuffer buffer;
        DebugStruct[] debug_array;
        int current_buffer_length;
        Matrix4x4 buf_projmat, buf_world2camera;
        Vector3 buf_scale;


        void CloseBuffer()
        {
            if (buffer != null)
            {
                buffer.Release();
                buffer = null;
            }
        }

        void OnEnable()
        {
            OnDisable();
            Camera.onPreRender += PreRenderCallback;
            Camera.onPostRender += PostRenderCallback;
            SceneView.onSceneGUIDelegate += SceneGUICallback;
        }

        void OnDisable()
        {
            Camera.onPreRender -= PreRenderCallback;
            Camera.onPostRender -= PostRenderCallback;
            SceneView.onSceneGUIDelegate -= SceneGUICallback;
            CloseBuffer();
        }

        void PreRenderCallback(Camera cam)
        {
            if (cam == null || cam.cameraType != CameraType.SceneView)
                return;

            int buflen = buffer_length < 1 ? 1 : buffer_length;
            if (current_buffer_length != buflen || freeze_view)
            {
                CloseBuffer();
                if (freeze_view)
                    return;
            }

            if (buffer == null)
            {
                buffer = new ComputeBuffer(buflen, DEBUG_STRUCT_SIZE, ComputeBufferType.Counter);
                current_buffer_length = buflen;
                most_recent_load = -1;
                debug_array = new DebugStruct[buflen];
            }

            Graphics.ClearRandomWriteTargets();
            Graphics.SetRandomWriteTarget(7, buffer, false);
            buffer.SetCounterValue(0);

            buf_projmat = cam.projectionMatrix;
            buf_world2camera = cam.worldToCameraMatrix;
            buf_scale = new Vector3(cam.scaledPixelWidth, cam.scaledPixelHeight, 1);
        }

        void PostRenderCallback(Camera cam)
        {
            if (cam == null || cam.cameraType != CameraType.SceneView)
                return;

            if (buffer != null)
            {
                /* a bit messy, this is just to know the final value of the counter in 'buffer' */
                var path = AssetDatabase.GUIDToAssetPath("64997cb862c601246b82aced336da5c8");
                var cs = AssetDatabase.LoadAssetAtPath<ComputeShader>(path);
                cs.SetBuffer(0, "_internal_debug_buffer", buffer);
                cs.Dispatch(0, 1, 1, 1);
            }
        }


        /******************************************************************/

        const int DEBUG_STRUCT_SIZE = 24;

        const uint _DEBUG_ROOT = 1;
        const uint _DEBUG_SET_COLOR = 2;
        const uint _DEBUG_SET_POS = 3;
        const uint _DEBUG_RESET_POS = 4;
        const uint _DEBUG_CHANGE_POS = 5;
        const uint _DEBUG_SPHERE = 10;
        const uint _DEBUG_VALUE1 = 11;
        const uint _DEBUG_VALUE2 = 12;
        const uint _DEBUG_VALUE3 = 13;
        const uint _DEBUG_VALUE4 = 14;
        const uint _DEBUG_COLOR_PATCH = 15;
        const uint _DEBUG_VECTOR = 16;
        const uint _DEBUG_DIRECTION = 17;
        const uint _DEBUG_CUBE = 18;
        const uint _DEBUG_SCREEN_DISC = 19;

        struct DebugStruct
        {
            public uint next;
            public uint kind;
            public Vector4 v;
        }

        float most_recent_load;
        int most_recent_count;
        uint[] display_roots;
        Matrix4x4 mat_screen2cam, mat_cam2world;
        Stack<uint> stack = new Stack<uint>();
        List<string> textlines = new List<string>();

        void SceneGUICallback(SceneView scene_view)
        {
            if (Event.current.type != EventType.Repaint)
                return;

            if (!freeze_view && (Time.unscaledTime != most_recent_load || display_roots == null ||
                                 display_roots.Length != display_count))
            {
                if (buffer == null)
                    return;

                buffer.GetData(debug_array, 0, 0, 1);
                most_recent_count = (int)debug_array[0].next;
                if (most_recent_count > debug_array.Length)
                    most_recent_count = debug_array.Length;
                buffer.GetData(debug_array, 0, 0, most_recent_count);

                Matrix4x4 times_half_plus_half = Matrix4x4.identity;
                times_half_plus_half.SetTRS(new Vector3(0.5f, 0.5f, 0), Quaternion.identity, new Vector3(0.5f, 0.5f, 1));
                mat_screen2cam = Matrix4x4.Inverse(Matrix4x4.Scale(buf_scale) * times_half_plus_half * buf_projmat);
                mat_cam2world = Matrix4x4.Inverse(buf_world2camera);

                display_roots = new uint[display_count];
                if (most_recent_count > 1)
                {
                    for (int i = 0; i < display_count; i++)
                    {
                        uint j = (uint)Random.Range(1, most_recent_count);
                        while (debug_array[j].next < j)
                            j = debug_array[j].next;
                        Debug.Assert(debug_array[j].kind == _DEBUG_ROOT);
                        display_roots[i] = j;
                    }
                }
                most_recent_load = Time.unscaledTime;
            }

            Handles.matrix = Matrix4x4.identity;
            stack.Clear();
            textlines.Clear();

            if (display_roots != null)
                for (int i = 0; i < display_roots.Length; i++)
                    DisplayHandle(display_roots[i]);
        }

        void DisplayHandle(uint j_root)
        {
            if (j_root == 0 || j_root >= most_recent_count)
                return;

            uint j = j_root;
            while (true)
            {
                j = debug_array[j].next;
                if (j >= most_recent_count)
                    break;
                if (debug_array[j].kind == _DEBUG_ROOT)
                {
                    Debug.Assert(j == j_root);
                    break;
                }
                stack.Push(j);
            }

            /* The SV_POSITION that we record from the fragment shader is in screen space.
             * It is not in clip space, even though that's how the vertex shader writes it.
             */
            Vector4 sv_pos = debug_array[j_root].v;
            Vector3 pt = mat_screen2cam.MultiplyPoint((Vector3)sv_pos);
            pt *= -sv_pos.w / pt.z;
            pt = mat_cam2world.MultiplyPoint(pt);
            Vector3 original_pt = pt;
            //Debug.Log(sv_pos + " => " + pt.x + ", " + pt.y + ", " + pt.z);

            //Vector3 center = (Vector3)pt / pt.w;
            Handles.color = Color.yellow;
            //Handles.DrawWireCube(pt, new Vector3(0.01f, 0.01f, 0.01f));

            const float SCREEN_FACTOR = 0.03f;
            Vector3 camforward = mat_cam2world.MultiplyVector(Vector3.forward);
            Handles.DrawSolidDisc(pt, camforward, HandleUtility.GetHandleSize(pt) * SCREEN_FACTOR);

            while (stack.Count > 0)
            {
                j = stack.Pop();
                Vector4 v = debug_array[j].v;
                switch (debug_array[j].kind)
                {
                    case _DEBUG_SET_COLOR:
                        Handles.color = v;
                        break;

                    case _DEBUG_SET_POS:
                        FlushText(pt);
                        pt = (Vector3)v;
                        break;

                    case _DEBUG_RESET_POS:
                        FlushText(pt);
                        pt = original_pt;
                        break;

                    case _DEBUG_CHANGE_POS:
                        FlushText(pt);
                        pt += (Vector3)v;
                        break;

                    case _DEBUG_VECTOR:
                        Handles.DrawLine(pt, pt + (Vector3)v);
                        break;

                    case _DEBUG_VALUE1:
                        textlines.Add(string.Format("{0:F5}", v.x));
                        break;

                    case _DEBUG_VALUE2:
                        textlines.Add(string.Format("{0:F5} {1:F5}", v.x, v.y));
                        break;

                    case _DEBUG_VALUE3:
                        textlines.Add(string.Format("{0:F5} {1:F5} {2:F5}", v.x, v.y, v.z));
                        break;

                    case _DEBUG_VALUE4:
                        textlines.Add(string.Format("{0:F5} {1:F5} {2:F5} {3:F5}", v.x, v.y, v.z, v.w));
                        break;

                    case _DEBUG_SPHERE:
                        Handles.DrawWireDisc(pt, Vector3.up, v.x);
                        Handles.DrawWireDisc(pt, Vector3.forward, v.x);
                        Handles.DrawWireDisc(pt, Vector3.right, v.x);
                        break;

                    case _DEBUG_SCREEN_DISC:
                        float screen_disc_size = HandleUtility.GetHandleSize(pt) * SCREEN_FACTOR;
                        Handles.DrawSolidDisc(pt, camforward, screen_disc_size * v.x);
                        break;
                }
            }
            FlushText(pt);
        }

        void FlushText(Vector3 pt)
        {
            if (textlines.Count > 0)
            {
                Handles.Label(pt, string.Join("\n", textlines));
                textlines.Clear();
            }
        }
    }
}
