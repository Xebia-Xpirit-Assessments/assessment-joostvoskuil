namespace eShop.WebApp.Services;

public class OrderingService(HttpClient httpClient)
{
    private readonly string remoteServiceBaseUrl = "/api/Orders/";

    public Task<OrderRecord[]> GetOrders()
    {
        return httpClient.GetFromJsonAsync<OrderRecord[]>(remoteServiceBaseUrl)!;
    }

    public Task<OrderDetailRecord> GetOrder(int orderNumber)
    {
        return httpClient.GetFromJsonAsync<OrderDetailRecord>($"{remoteServiceBaseUrl}{orderNumber}")!;
    }

    public Task CreateOrder(CreateOrderRequest request, Guid requestId)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Post, remoteServiceBaseUrl);
        requestMessage.Headers.Add("x-requestid", requestId.ToString());
        requestMessage.Content = JsonContent.Create(request);
        return httpClient.SendAsync(requestMessage);
    }

    public async Task<HttpResponseMessage> RequestReturn(int orderNumber, IReadOnlyDictionary<int, int> itemsToReturn, Guid requestId)
    {
        var requestMessage = new HttpRequestMessage(HttpMethod.Put, $"{remoteServiceBaseUrl}return");
        requestMessage.Headers.Add("x-requestid", requestId.ToString());
        requestMessage.Content = JsonContent.Create(new RequestOrderReturnRequest(
            orderNumber,
            itemsToReturn.Select(kvp => new ReturnOrderItemRequest(kvp.Key, kvp.Value)).ToList()));
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
    public int EligibleReturnUnits => Units - ReturnedUnits;
}

public record OrderDetailRecord(
    int OrderNumber,
    DateTime Date,
    string Status,
    string Description,
    decimal Total,
    List<OrderItemRecord> OrderItems);

public record ReturnOrderItemRequest(int ProductId, int Units);

public record RequestOrderReturnRequest(int OrderNumber, List<ReturnOrderItemRequest> Items);
