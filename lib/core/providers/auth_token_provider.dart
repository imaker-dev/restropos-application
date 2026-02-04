import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final authTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjg5LCJ1dWlkIjoiMDk2OTYzYjUtYzQwNy00NTIxLWI0ZWEtYmZhNjhiZTQzYmYwIiwiZW1haWwiOm51bGwsInJvbGVzIjpbImNhcHRhaW4iXSwib3V0bGV0SWQiOjEsImlhdCI6MTc3MDE4NjQ1MSwiZXhwIjoxNzcyNzc4NDUxLCJpc3MiOiJyZXN0cm8tcG9zIn0.Tvm1jF4U8C__w6Gy3ncjsfWfCuTR6FVLJJy6AZCA-_A";
});
