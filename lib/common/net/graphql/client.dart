import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/repositories.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/users.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';

Future<GraphQLClient> _client(token) async {
  final HttpLink httpLink = HttpLink(
    'https://api.github.com/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () => '$token',
  );

  final Link link = authLink.concat(httpLink);
  var path = await CommonUtils.getApplicationDocumentsPath();
  final store = await HiveStore.open(path: path);
  return GraphQLClient(
    cache: GraphQLCache(store: store),
    link: link,
  );
}

GraphQLClient? _innerClient;

initClient(token) async {
  _innerClient ??= await _client(token);
}

releaseClient() {
  _innerClient = null;
}

Future<QueryResult>? getRepository(String owner, String? name) async {
  final QueryOptions options = QueryOptions(
      document: gql(readRepository),
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}

Future<QueryResult>? getTrendUser(String location, {String? cursor}) async {
  var variables = cursor == null
      ? <String, dynamic>{
          'location': "location:$location sort:followers",
        }
      : <String, dynamic>{
          'location': "location:$location sort:followers",
          'after': cursor,
        };
  final QueryOptions options = QueryOptions(
      document: gql(cursor == null ? readTrendUser : readTrendUserByCursor),
      variables: variables,
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient!.query(options);
}
