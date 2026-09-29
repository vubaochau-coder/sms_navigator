import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST('/api/v1/devices/register')
  Future<dynamic> registerDevice(@Body() Map<String, dynamic> body);

  @PUT('/api/v1/devices/fcm-token')
  Future<dynamic> updateFcmToken(@Body() Map<String, dynamic> body);

  @POST('/api/v1/pair/init')
  Future<dynamic> initPair(@Body() Map<String, dynamic> body);

  @POST('/api/v1/pair/confirm')
  Future<dynamic> confirmPair(@Body() Map<String, dynamic> body);

  @GET('/api/v1/pair/status/{pairId}')
  Future<dynamic> getPairStatus(@Path('pairId') String pairId);

  @DELETE('/api/v1/pair/{pairId}')
  Future<dynamic> revokePair(@Path('pairId') String pairId);

  @POST('/api/v1/relay')
  Future<dynamic> relayOtp(@Body() Map<String, dynamic> body);

  @GET('/api/v1/relay/pending/{pairId}')
  Future<dynamic> getPendingMessages(@Path('pairId') String pairId);

  @GET('/api/v1/relay/history')
  Future<dynamic> getRelayHistory(
    @Query('date') String date,
    @Query('pair_id') String? pairId,
  );
}

