import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/repositories.dart';

GraphQLClient _client(token) {
  final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink _authLink = AuthLink(
    getToken: () => '$token',
  );

  final Link _link = _authLink.concat(_httpLink);

  return GraphQLClient(
    cache: OptimisticCache(
      dataIdFromObject: typenameDataIdFromObject,
    ),
    link: _link,
  );
}

GraphQLClient _innerClient;

initClient(token) {
  _innerClient ??= _client(token);
}

releaseClient() {
  _innerClient = null;
}

Future<QueryResult> getRepository(String owner, String name) async {
  final QueryOptions _options = QueryOptions(
      document: readRepository,
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
      },
      fetchPolicy: FetchPolicy.noCache);
  return await _innerClient.query(_options);
}
