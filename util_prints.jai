#import "Basic";
#import "Math";

// Helper function
print_mat4 :: (name: string, mat: Matrix4) {
  print("  [ % ]\n", name);
  print("[%, %, %, %]\n",   mat._11, mat._12, mat._13, mat._14); 
  print("[%, %, %, %]\n",   mat._21, mat._22, mat._23, mat._24); 
  print("[%, %, %, %]\n",   mat._31, mat._32, mat._33, mat._34); 
  print("[%, %, %, %]\n\n", mat._41, mat._42, mat._43, mat._44); 
}

