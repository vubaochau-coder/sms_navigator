import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_endpoints.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST(ApiEndpoints.registerDevice)
  Future<dynamic> registerDevice(
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @PUT(ApiEndpoints.updateFcmToken)
  Future<dynamic> updateFcmToken(
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @POST(ApiEndpoints.initPair)
  Future<dynamic> initPair(
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @POST(ApiEndpoints.confirmPair)
  Future<dynamic> confirmPair(
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET(ApiEndpoints.pairStatus)
  Future<dynamic> getPairStatus(
    @Path('pairId') String pairId, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @DELETE(ApiEndpoints.revokePair)
  Future<dynamic> revokePair(
    @Path('pairId') String pairId, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @PATCH(ApiEndpoints.togglePair)
  Future<dynamic> togglePairActive(
    @Path('pairId') String pairId,
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET(ApiEndpoints.pairedReceivers)
  Future<dynamic> getPairedReceivers({
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET(ApiEndpoints.pairedSenders)
  Future<dynamic> getPairedSenders({@CancelRequest() CancelToken? cancelToken});

  @POST(ApiEndpoints.relay)
  Future<dynamic> relayOtp(
    @Body() Map<String, dynamic> body, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET(ApiEndpoints.pendingMessages)
  Future<dynamic> getPendingMessages(
    @Path('pairId') String pairId, {
    @CancelRequest() CancelToken? cancelToken,
  });

  @GET(ApiEndpoints.relayHistory)
  Future<dynamic> getRelayHistory(
    @Query('date') String date,
    @Query('pair_id') String? pairId, {
    @CancelRequest() CancelToken? cancelToken,
  });
}
