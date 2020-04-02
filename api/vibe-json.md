# Vibe.d Json API

[up](../README.md)

Theese are some utilities that helps you to write easier asserts for the [Json](https://vibed.org/api/vibe.data.json/) data type provided by the [vibe.d](https://vibed.org/) library.

## Setup

1. Include the vibe assert package package: `fluent-asserts-vibe`
2. Import the module: `import fluent.asserts.vibe.json` or `import fluent.asserts.vibe`

## Summary

- [Keys](#keys)

## Examples

### Keys

`string[] keys(Json obj, const string file = __FILE__, const size_t line = __LINE__)`

Returns an array that contains the keys of an Json object.

Success expectations
```D
    Json.emptyObject.keys.length.should.equal(0);
```

```D
    auto obj = Json.emptyObject;
    obj["key1"] = 1;
    obj["key2"] = 3;

    obj.keys.length.should.equal(2);
    obj.keys.should.contain(["key1", "key2"]);
```

Failing expectations
```D
    Json.emptyArray.keys.should.contain(["key1", "key2"]);
    // fails with: The json should be an object. `array` found.
```
