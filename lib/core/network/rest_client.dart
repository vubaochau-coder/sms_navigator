import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_endpoints.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST(ApiEndpoints.registerDevice)
  Future<dynamic> registerDevice(@Body() Map<String, dynamic> body);

  @PUT(ApiEndpoints.updateFcmToken)
  Future<dynamic> updateFcmToken(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.initPair)
  Future<dynamic> initPair(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.confirmPair)
  Future<dynamic> confirmPair(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.pairStatus)
  Future<dynamic> getPairStatus(@Path('pairId') String pairId);

  @DELETE(ApiEndpoints.revokePair)
  Future<dynamic> revokePair(@Path('pairId') String pairId);

  @PATCH(ApiEndpoints.togglePair)
  Future<dynamic> togglePairActive(
    @Path('pairId') String pairId,
    @Body() Map<String, dynamic> body,
  );

  @GET(ApiEndpoints.pairedReceivers)
  Future<dynamic> getPairedReceivers();

  @GET(ApiEndpoints.pairedSenders)
  Future<dynamic> getPairedSenders();

  @POST(ApiEndpoints.relay)
  Future<dynamic> relayOtp(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.pendingMessages)
  Future<dynamic> getPendingMessages(@Path('pairId') String pairId);

  @GET(ApiEndpoints.relayHistory)
  Future<dynamic> getRelayHistory(
    @Query('date') String date,
    @Query('pair_id') String? pairId,
  );
}
