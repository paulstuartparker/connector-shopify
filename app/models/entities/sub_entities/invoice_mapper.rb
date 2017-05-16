class Entities::SubEntities::InvoiceMapper
  extend HashMapper
  extend MapperHelper

  def self.invoice_references
    {
      record_references: %w(person_id lines/item_id),
      id_references: %w(lines/id)
    }
  end

  STATUS_MAPPING_INV = {
      'authorized' => 'AUTHORISED',
      'pending' => 'DRAFT',
      'paid' => 'PAID',
      'partially_paid' => 'AUTHORISED',
      'voided' => 'VOIDED'
      }

  map from('/person_id'), to('/customer/id')
  map from('/transaction_date'), to('/created_at')
  map from('/transaction_number'), to('/order_number')
  map from('/title'), to('/name')
  map from('/public_note'), to('/note')

  map from('/shipping_address/line1'), to('shipping_address/address1')
  map from('/shipping_address/line2'), to('shipping_address/address2')
  map from('/shipping_address/city'), to('shipping_address/city')
  map from('/shipping_address/region'), to('shipping_address/province')
  map from('/shipping_address/postal_code'), to('shipping_address/zip')
  map from('/shipping_address/country'), to('shipping_address/country_code')

  map from('/billing_address/line1'), to('billing_address/address1')
  map from('/billing_address/line2'), to('billing_address/address2')
  map from('/billing_address/city'), to('billing_address/city')
  map from('/billing_address/region'), to('billing_address/province')
  map from('/billing_address/postal_code'), to('billing_address/zip')
  map from('/billing_address/country'), to('billing_address/country_code')

  map from('/lines'), to('/line_items'), using: Entities::SubEntities::LineMapper
  map from('/lines_shipping'), to('/shipping_lines'), using: Entities::SubEntities::LineMapper

  before_denormalize do |input, output|
    input['line_items']&.each do |line|
      line['taxes_included'] = input['taxes_included']
    end

    input
  end

  after_denormalize do |input, output|
    output[:status] = STATUS_MAPPING_INV[input['financial_status']] if input['financial_status']
    output[:type] = input['kind'] != 'refund' ? 'CUSTOMER' : 'SUPPLIER'
    output[:lines].concat(output.delete(:lines_shipping))

    output[:lines] << {
      id: 'shopify-discount',
      quantity: 1,
      description: 'Discount',
      unit_price: {
        net_amount: - input['total_discounts'],
        tax_amount: 0.0,
        currency: input['currency']
      }
    } if input['total_discounts'].to_f > 0

    output = set_lines_currency(output, input['currency'])

    if input['financial_status'] == 'paid'
      output[:balance] = 0.0
      output[:deposit] = input.dig('total_price').to_f
    end

    output
  end
end
