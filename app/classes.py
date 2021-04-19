from app.api import predict

## O (n log n)
def make_class(arr):

    if len(arr) <= 1:
        return arr
    else:
        return make_class([x for x in arr[1:] if x < arr[0]])
        + [arr[0]]
        + make_class([x for x in arr[1:] if x >= arr[0]])