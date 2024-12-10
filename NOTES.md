


## Sending JSON messages from the client

```javascript
channel.push("new_message", {body: {
  name: "John",
  age: 30,
  address: {
    street: "123 Main St",
    city: "Example City"
  }
}})
```



## Sending an image message from the client

You can test this by sending an image message from the client like this:

```javascript
// In browser console
const fileInput = document.createElement('input');
fileInput.type = 'file';
fileInput.accept = 'image/*';

fileInput.onchange = (e) => {
  const file = e.target.files[0];
  const reader = new FileReader();
  
  reader.onload = (event) => {
    const img = new Image();
    img.onload = () => {
      channel.push("new_message", {
        body: {
          type: "image",
          data: event.target.result,
          width: img.width,
          height: img.height,
          size: file.size,
          filename: file.name,
          type: file.type
        }
      });
    };
    img.src = event.target.result;
  };
  
  reader.readAsDataURL(file);
};

fileInput.click();
```

## Sending an SVG path message from the client

You can test this by sending an SVG path message from the client like this:

```javascript
// Example: sending a simple SVG path (a heart shape)
channel.push("new_message", {
  body: {
    type: "svg_path",
    path: "M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z",
    width: 100,
    height: 100,
    viewBox: "0 0 100 100"
  }
});

// Example: sending a more complex path
channel.push("new_message", {
  body: {
    type: "svg_path",
    path: "M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80",
    width: 200,
    height: 160,
    viewBox: "0 0 200 160"
  }
});
```