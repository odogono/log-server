


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

