namespace eShop.WebApp.Services;

public class OrderingService(HttpClient httpClient)
{
    private readonly string remoteServiceBaseUrl = "/api/Orders/";

    public Task<OrderRecord[]> GetOrders()
    {
        return httpClient.GetFromJsonAsync<OrderRecord[]>(remoteServiceBaseUrl)!;
    }

    public Task<OrderDetailRecord?> GetOrder(int orderId)
    {
        return httpClient.GetFromJsonAsync<OrderDetailRecord>($"{remoteServiceBaseUrl}{orderId}");
    }

    public Task CreateOrder(CreateOrderRequest request, Guid requestId)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Post, remoteServiceBaseUrl);
        requestMessage.Headers.Add("x-requestid", requestId.ToString());
        requestMessage.Content = JsonContent.Create(request);
        return httpClient.SendAsync(requestMessage);
    }

    public Task<HttpResponseMessage> RequestReturn(RequestOrderReturnRequest request, Guid requestId)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Put, $"{remoteServiceBaseUrl}return");
        requestMessage.Headers.Add("x-requestid", requestId.ToString());
        requestMessage.Content = JsonContent.Create(request);
        return httpClient.SendAsync(requestMessage);
    }
}

public record OrderRecord(
    int OrderNumber,
    DateTime Date,
    string Status,
    decimal Total);

public record OrderItemRecord(
    int ProductId,
    string ProductName,
    int Units,
    double UnitPrice,
    string PictureUrl,
    int ReturnedUnits);

public record OrderDetailRecord(
    int OrderNumber,
    DateTime Date,
    string Status,
    string Description,
    decimal Total,
    List<OrderItemRecord> OrderItems);

public record RequestOrderReturnRequest(int OrderNumber, Dictionary<int, int> ItemsToReturn);

