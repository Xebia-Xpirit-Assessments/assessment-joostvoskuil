namespace eShop.WebApp.Services;

public class OrderingService(HttpClient httpClient)
{
    private readonly string remoteServiceBaseUrl = "/api/Orders/";

    public Task<OrderRecord[]> GetOrders()
    {
        return httpClient.GetFromJsonAsync<OrderRecord[]>(remoteServiceBaseUrl)!;
    }

    public Task<OrderDetailRecord> GetOrder(int orderId)
    {
        return httpClient.GetFromJsonAsync<OrderDetailRecord>($"{remoteServiceBaseUrl}{orderId}")!;
    }

    public Task CreateOrder(CreateOrderRequest request, Guid requestId)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Post, remoteServiceBaseUrl);
        requestMessage.Headers.Add("x-requestid", requestId.ToString());
        requestMessage.Content = JsonContent.Create(request);
        return httpClient.SendAsync(requestMessage);
    }

    public async Task<HttpResponseMessage> RequestReturn(int orderId, IReadOnlyList<OrderItemReturnRequestRecord> items)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Post, $"{remoteServiceBaseUrl}{orderId}/return");
        requestMessage.Content = JsonContent.Create(new OrderReturnRequestRecord(items.ToList()));
        return await httpClient.SendAsync(requestMessage);
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
    int ReturnedUnits)
{
    public int ReturnEligibleUnits => Units - ReturnedUnits;
}

public record OrderDetailRecord(
    int OrderNumber,
    DateTime Date,
    string Status,
    string Description,
    string Street,
    string City,
    string State,
    string Zipcode,
    string Country,
    List<OrderItemRecord> OrderItems,
    decimal Total);

public record OrderItemReturnRequestRecord(int ProductId, int Units);

public record OrderReturnRequestRecord(List<OrderItemReturnRequestRecord> Items);
