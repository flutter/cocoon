import 'package:gql/ast.dart' as _i1;

const LabeledPullRequcodeestsWithReviews = _i1.OperationDefinitionNode(
    type: _i1.OperationType.query,
    name: _i1.NameNode(value: 'LabeledPullRequcodeestsWithReviews'),
    variableDefinitions: [
      _i1.VariableDefinitionNode(
          variable: _i1.VariableNode(name: _i1.NameNode(value: 'sOwner')),
          type: _i1.NamedTypeNode(
              name: _i1.NameNode(value: 'String'), isNonNull: true),
          defaultValue: _i1.DefaultValueNode(value: null),
          directives: []),
      _i1.VariableDefinitionNode(
          variable: _i1.VariableNode(name: _i1.NameNode(value: 'sName')),
          type: _i1.NamedTypeNode(
              name: _i1.NameNode(value: 'String'), isNonNull: true),
          defaultValue: _i1.DefaultValueNode(value: null),
          directives: []),
      _i1.VariableDefinitionNode(
          variable: _i1.VariableNode(name: _i1.NameNode(value: 'sLabelName')),
          type: _i1.NamedTypeNode(
              name: _i1.NameNode(value: 'String'), isNonNull: true),
          defaultValue: _i1.DefaultValueNode(value: null),
          directives: [])
    ],
    directives: [],
    selectionSet: _i1.SelectionSetNode(selections: [
      _i1.FieldNode(
          name: _i1.NameNode(value: 'repository'),
          alias: null,
          arguments: [
            _i1.ArgumentNode(
                name: _i1.NameNode(value: 'owner'),
                value: _i1.VariableNode(name: _i1.NameNode(value: 'sOwner'))),
            _i1.ArgumentNode(
                name: _i1.NameNode(value: 'name'),
                value: _i1.VariableNode(name: _i1.NameNode(value: 'sName')))
          ],
          directives: [],
          selectionSet: _i1.SelectionSetNode(selections: [
            _i1.FieldNode(
                name: _i1.NameNode(value: 'labels'),
                alias: null,
                arguments: [
                  _i1.ArgumentNode(
                      name: _i1.NameNode(value: 'first'),
                      value: _i1.IntValueNode(value: '1')),
                  _i1.ArgumentNode(
                      name: _i1.NameNode(value: 'query'),
                      value: _i1.VariableNode(
                          name: _i1.NameNode(value: 'sLabelName')))
                ],
                directives: [],
                selectionSet: _i1.SelectionSetNode(selections: [
                  _i1.FieldNode(
                      name: _i1.NameNode(value: 'nodes'),
                      alias: null,
                      arguments: [],
                      directives: [],
                      selectionSet: _i1.SelectionSetNode(selections: [
                        _i1.FieldNode(
                            name: _i1.NameNode(value: 'id'),
                            alias: null,
                            arguments: [],
                            directives: [],
                            selectionSet: null),
                        _i1.FieldNode(
                            name: _i1.NameNode(value: 'pullRequests'),
                            alias: null,
                            arguments: [
                              _i1.ArgumentNode(
                                  name: _i1.NameNode(value: 'first'),
                                  value: _i1.IntValueNode(value: '100')),
                              _i1.ArgumentNode(
                                  name: _i1.NameNode(value: 'states'),
                                  value: _i1.EnumValueNode(
                                      name: _i1.NameNode(value: 'OPEN'))),
                              _i1.ArgumentNode(
                                  name: _i1.NameNode(value: 'orderBy'),
                                  value: _i1.ObjectValueNode(fields: [
                                    _i1.ObjectFieldNode(
                                        name: _i1.NameNode(value: 'direction'),
                                        value: _i1.EnumValueNode(
                                            name: _i1.NameNode(value: 'ASC'))),
                                    _i1.ObjectFieldNode(
                                        name: _i1.NameNode(value: 'field'),
                                        value: _i1.EnumValueNode(
                                            name: _i1.NameNode(
                                                value: 'CREATED_AT')))
                                  ]))
                            ],
                            directives: [],
                            selectionSet: _i1.SelectionSetNode(selections: [
                              _i1.FieldNode(
                                  name: _i1.NameNode(value: 'nodes'),
                                  alias: null,
                                  arguments: [],
                                  directives: [],
                                  selectionSet:
                                      _i1.SelectionSetNode(selections: [
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'author'),
                                        alias: null,
                                        arguments: [],
                                        directives: [],
                                        selectionSet:
                                            _i1.SelectionSetNode(selections: [
                                          _i1.FieldNode(
                                              name:
                                                  _i1.NameNode(value: 'login'),
                                              alias: null,
                                              arguments: [],
                                              directives: [],
                                              selectionSet: null)
                                        ])),
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'id'),
                                        alias: null,
                                        arguments: [],
                                        directives: [],
                                        selectionSet: null),
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'number'),
                                        alias: null,
                                        arguments: [],
                                        directives: [],
                                        selectionSet: null),
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'mergeable'),
                                        alias: null,
                                        arguments: [],
                                        directives: [],
                                        selectionSet: null),
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'commits'),
                                        alias: null,
                                        arguments: [
                                          _i1.ArgumentNode(
                                              name: _i1.NameNode(value: 'last'),
                                              value:
                                                  _i1.IntValueNode(value: '1'))
                                        ],
                                        directives: [],
                                        selectionSet: _i1.SelectionSetNode(
                                            selections: [
                                              _i1.FieldNode(
                                                  name: _i1.NameNode(
                                                      value: 'nodes'),
                                                  alias: null,
                                                  arguments: [],
                                                  directives: [],
                                                  selectionSet:
                                                      _i1.SelectionSetNode(
                                                          selections: [
                                                        _i1.FieldNode(
                                                            name: _i1.NameNode(
                                                                value:
                                                                    'commit'),
                                                            alias: null,
                                                            arguments: [],
                                                            directives: [],
                                                            selectionSet: _i1
                                                                .SelectionSetNode(
                                                                    selections: [
                                                                  _i1.FieldNode(
                                                                      name: _i1.NameNode(
                                                                          value:
                                                                              'abbreviatedOid'),
                                                                      alias:
                                                                          null,
                                                                      arguments: [],
                                                                      directives: [],
                                                                      selectionSet:
                                                                          null),
                                                                  _i1.FieldNode(
                                                                      name: _i1.NameNode(
                                                                          value:
                                                                              'oid'),
                                                                      alias:
                                                                          null,
                                                                      arguments: [],
                                                                      directives: [],
                                                                      selectionSet:
                                                                          null),
                                                                  _i1.FieldNode(
                                                                      name: _i1.NameNode(
                                                                          value:
                                                                              'committedDate'),
                                                                      alias:
                                                                          null,
                                                                      arguments: [],
                                                                      directives: [],
                                                                      selectionSet:
                                                                          null),
                                                                  _i1.FieldNode(
                                                                      name: _i1.NameNode(
                                                                          value:
                                                                              'pushedDate'),
                                                                      alias:
                                                                          null,
                                                                      arguments: [],
                                                                      directives: [],
                                                                      selectionSet:
                                                                          null),
                                                                  _i1.FieldNode(
                                                                      name: _i1.NameNode(
                                                                          value:
                                                                              'status'),
                                                                      alias:
                                                                          null,
                                                                      arguments: [],
                                                                      directives: [],
                                                                      selectionSet:
                                                                          _i1.SelectionSetNode(
                                                                              selections: [
                                                                            _i1.FieldNode(
                                                                                name: _i1.NameNode(value: 'contexts'),
                                                                                alias: null,
                                                                                arguments: [],
                                                                                directives: [],
                                                                                selectionSet: _i1.SelectionSetNode(selections: [
                                                                                  _i1.FieldNode(name: _i1.NameNode(value: 'context'), alias: null, arguments: [], directives: [], selectionSet: null),
                                                                                  _i1.FieldNode(name: _i1.NameNode(value: 'state'), alias: null, arguments: [], directives: [], selectionSet: null)
                                                                                ]))
                                                                          ]))
                                                                ]))
                                                      ]))
                                            ])),
                                    _i1.FieldNode(
                                        name: _i1.NameNode(value: 'reviews'),
                                        alias: null,
                                        arguments: [
                                          _i1.ArgumentNode(
                                              name:
                                                  _i1.NameNode(value: 'first'),
                                              value: _i1.IntValueNode(
                                                  value: '100')),
                                          _i1.ArgumentNode(
                                              name:
                                                  _i1.NameNode(value: 'states'),
                                              value: _i1.ListValueNode(values: [
                                                _i1.EnumValueNode(
                                                    name: _i1.NameNode(
                                                        value: 'APPROVED')),
                                                _i1.EnumValueNode(
                                                    name: _i1.NameNode(
                                                        value:
                                                            'CHANGES_REQUESTED'))
                                              ]))
                                        ],
                                        directives: [],
                                        selectionSet:
                                            _i1.SelectionSetNode(selections: [
                                          _i1.FieldNode(
                                              name:
                                                  _i1.NameNode(value: 'nodes'),
                                              alias: null,
                                              arguments: [],
                                              directives: [],
                                              selectionSet:
                                                  _i1.SelectionSetNode(
                                                      selections: [
                                                    _i1.FieldNode(
                                                        name: _i1.NameNode(
                                                            value: 'author'),
                                                        alias: null,
                                                        arguments: [],
                                                        directives: [],
                                                        selectionSet: _i1
                                                            .SelectionSetNode(
                                                                selections: [
                                                              _i1.FieldNode(
                                                                  name: _i1
                                                                      .NameNode(
                                                                          value:
                                                                              'login'),
                                                                  alias: null,
                                                                  arguments: [],
                                                                  directives: [],
                                                                  selectionSet:
                                                                      null)
                                                            ])),
                                                    _i1.FieldNode(
                                                        name: _i1.NameNode(
                                                            value:
                                                                'authorAssociation'),
                                                        alias: null,
                                                        arguments: [],
                                                        directives: [],
                                                        selectionSet: null),
                                                    _i1.FieldNode(
                                                        name: _i1.NameNode(
                                                            value: 'state'),
                                                        alias: null,
                                                        arguments: [],
                                                        directives: [],
                                                        selectionSet: null)
                                                  ]))
                                        ]))
                                  ]))
                            ]))
                      ]))
                ]))
          ]))
    ]));
const document =
    _i1.DocumentNode(definitions: [LabeledPullRequcodeestsWithReviews]);
