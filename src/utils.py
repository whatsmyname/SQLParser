# -*- coding:utf-8 -*-

def _serialize(value, memo):
    if isinstance(value, Serialize):
        return value.serialize(memo)
    elif isinstance(value, list):
        return [_serialize(elem, memo) for elem in value]
    elif isinstance(value, frozenset):
        return list(value)  # TODO reversible?
    elif isinstance(value, dict):
        return {key: _serialize(elem, memo) for key, elem in value.items()}
    # assert value is None or isinstance(value, (int, float, str, tuple)), value
    return value


def _deserialize(data, namespace, memo):
    if isinstance(data, dict):
        if '__type__' in data:  # Object
            class_ = namespace[data['__type__']]
            return class_.deserialize(data, memo)
        elif '@' in data:
            return memo[data['@']]
        return {key: _deserialize(value, namespace, memo) for key, value in data.items()}
    elif isinstance(data, list):
        return [_deserialize(value, namespace, memo) for value in data]
    return data


class Serialize:
    """Safe-ish serialization interface that doesn't rely on Pickle

    Attributes:
        __serialize_fields__ (List[str]): Fields (aka attributes) to serialize.
        __serialize_namespace__ (list): List of classes that deserialization is allowed to instantiate.
                                        Should include all field types that aren't builtin types.
    """

    def memo_serialize(self, types_to_memoize):
        memo = SerializeMemoizer(types_to_memoize)
        return self.serialize(memo), memo.serialize()

    def serialize(self, memo=None):
        if memo and memo.in_types(self):
            return {'@': memo.memoized.get(self)}

        fields = getattr(self, '__serialize_fields__')
        res = {f: _serialize(getattr(self, f), memo) for f in fields}
        res['__type__'] = type(self).__name__
        if hasattr(self, '_serialize'):
            self._serialize(res, memo)
        return res

    @classmethod
    def deserialize(cls, data, memo):
        namespace = getattr(cls, '__serialize_namespace__', [])
        namespace = {c.__name__: c for c in namespace}

        fields = getattr(cls, '__serialize_fields__')

        if '@' in data:
            return memo[data['@']]

        inst = cls.__new__(cls)
        for f in fields:
            try:
                setattr(inst, f, _deserialize(data[f], namespace, memo))
            except KeyError as e:
                raise KeyError("Cannot find key for class", cls, e)

        if hasattr(inst, '_deserialize'):
            inst._deserialize()

        return inst


class SerializeMemoizer(Serialize):
    "A version of serialize that memoizes objects to reduce space"

    __serialize_fields__ = 'memoized',

    def __init__(self, types_to_memoize):
        self.types_to_memoize = tuple(types_to_memoize)
        self.memoized = Enumerator()

    def in_types(self, value):
        return isinstance(value, self.types_to_memoize)

    def serialize(self):
        return _serialize(self.memoized.reversed(), None)

    @classmethod
    def deserialize(cls, data, namespace, memo):
        return _deserialize(data, namespace, memo)


class Enumerator(Serialize):
    def __init__(self):
        self.enums = {}

    def get(self, item):
        if item not in self.enums:
            self.enums[item] = len(self.enums)
        return self.enums[item]

    def __len__(self):
        return len(self.enums)

    def reversed(self):
        r = {v: k for k, v in self.enums.items()}
        assert len(r) == len(self.enums)
        return r
