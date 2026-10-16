# TDD example

One list item, one test: "retries a failing operation up to 3 times".

```js
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };
  const result = await retryOperation(operation);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

Run it and confirm it fails because `retryOperation` is missing, not because
of a typo or setup error. Then write the least code that passes, and let the
next list item (for example, giving up after the third failure) force the
general solution.
